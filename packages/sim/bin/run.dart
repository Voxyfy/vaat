// Terminal koşturucusu. Denge testi ve hata ayıklama için, oyunun parçası değil.
//
// Kullanım:
//   dart run bin/run.dart sim --weeks 260 --rate 0.012 --skim 0.13 --seed 42
//   dart run bin/run.dart verify
import 'dart:io';

import 'package:vaat_sim/vaat_sim.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    _usage();
    exit(64);
  }
  final command = args.first;
  final flags = _parseFlags(args.skip(1));
  switch (command) {
    case 'sim':
      _runSim(flags);
    case 'verify':
      _runVerify();
    case 'sweep':
      _runSweep(flags);
    case 'strategy':
      _runStrategy(flags);
    default:
      _usage();
      exit(64);
  }
}

void _usage() {
  stdout.writeln('Kullanım:');
  stdout.writeln(
    '  run.dart sim [--weeks N] [--rate R] [--skim S] [--seed N] [--cash C] [--quiet]',
  );
  stdout.writeln('  run.dart verify');
  stdout.writeln(
    '  run.dart sweep [--seeds N] [--weeks N]   vaat oranı x seed taraması',
  );
}

Map<String, String> _parseFlags(Iterable<String> args) {
  final flags = <String, String>{};
  final list = args.toList();
  for (var i = 0; i < list.length; i++) {
    final a = list[i];
    if (!a.startsWith('--')) continue;
    final key = a.substring(2);
    final hasValue = i + 1 < list.length && !list[i + 1].startsWith('--');
    flags[key] = hasValue ? list[++i] : 'true';
  }
  return flags;
}

/// Sema turlerini okur.
List<SchemeType> _loadSchemes(Directory content) =>
    SchemeType.listFromJsonString(
      File('${content.path}/schemes.json').readAsStringSync(),
    );

/// `content/` klasörünü bulmak için yukarı doğru yürür. Neden: komut hem
/// depo kökünden hem packages/sim içinden çalıştırılabilsin.
Directory _findContentDir() {
  var dir = Directory.current;
  for (var i = 0; i < 5; i++) {
    final candidate = Directory('${dir.path}/content');
    if (candidate.existsSync()) return candidate;
    dir = dir.parent;
  }
  stderr.writeln('content/ klasörü bulunamadı. Depo içinden çalıştırın.');
  exit(66);
}

void _runSim(Map<String, String> flags) {
  final content = _findContentDir();
  final cfg = BalanceConfig.fromJsonString(
    File('${content.path}/balance.json').readAsStringSync(),
  );
  final defs = <EventDef>[];
  for (final f in Directory('${content.path}/events').listSync()) {
    if (f is File && f.path.endsWith('.json')) {
      defs.addAll(EventDef.listFromJsonString(f.readAsStringSync()));
    }
  }
  final events = EventEngine(defs);
  final schemes = _loadSchemes(content);
  final typeId = flags['scheme'] ?? 'classicPonzi';
  final type = schemes.firstWhere(
    (t) => t.id == typeId,
    orElse: () {
      stderr.writeln('Bilinmeyen şema: $typeId');
      stderr.writeln('Seçenekler: ${schemes.map((t) => t.id).join(', ')}');
      exit(64);
    },
  );

  final weeks = int.parse(flags['weeks'] ?? '260');
  final rate = double.parse(flags['rate'] ?? '${type.startRateWeekly}');
  final skim = double.parse(flags['skim'] ?? '0.13');
  final seed = int.parse(flags['seed'] ?? '42');
  final cash = double.parse(flags['cash'] ?? '${type.startCash}');
  final quiet = flags['quiet'] == 'true';

  final rng = SimRng(seed);
  var state = SchemeState.initial(
    type: type,
    cash: cash,
    seedInvestors: 10,
    seedTicket: cfg.segments[type.seedSegment]!.ticket,
    promisedRateWeekly: rate,
    skim: skim,
  );

  stdout.writeln(
    'Vaat sim | ${type.name} | seed $seed | vaat ${(rate * 100).toStringAsFixed(2)}%/hafta | skim ${(skim * 100).toStringAsFixed(0)}%',
  );
  stdout.writeln(
    'hafta | kasa        | ekstre      | karşılama | yatırımcı | panik | şüphe | giriş     | çekim',
  );

  for (var w = 0; w < weeks && !state.isOver; w++) {
    // Terminal oyuncusu pasif: olaylara cevap vermez, son seçenek uygulanır.
    // Denge ölçümü için "en kötü oyuncu" tabanı budur.
    final result = tick(state, const [], rng, cfg, events, type);
    state = result.state;
    final show =
        !quiet &&
        (state.week % 4 == 0 || state.isOver || result.log.isNotEmpty);
    if (show) {
      stdout.writeln(
        '${state.week.toString().padLeft(5)} | '
        '${_money(state.cash).padLeft(11)} | '
        '${_money(state.promisedTotal).padLeft(11)} | '
        '${(state.coverage * 100).toStringAsFixed(0).padLeft(8)}% | '
        '${state.investorCount.toString().padLeft(9)} | '
        '${state.panic.toStringAsFixed(2).padLeft(5)} | '
        '${state.suspicion.toStringAsFixed(0).padLeft(5)} | '
        '${_money(result.inflow).padLeft(9)} | '
        '${_money(result.withdrawDemand)}',
      );
      for (final line in result.log) {
        stdout.writeln('        · $line');
      }
    }
  }

  stdout.writeln('');
  if (state.isOver) {
    stdout.writeln('SON: ${state.end!.name} — ${state.endReason}');
  } else {
    stdout.writeln('SON: $weeks hafta sonunda hâlâ ayakta.');
  }
  stdout.writeln(
    'Toplam giriş ${_money(state.totalInflow)}, ödenen ${_money(state.totalPaidOut)}, cep ${_money(state.totalSkimmed)}, kasa ${_money(state.cash)}',
  );
  stdout.writeln(
    'Delik: ${_money(state.hole)} (ekstre ${_money(state.promisedTotal)} vs kasa ${_money(state.cash)})',
  );
}

/// Denge taraması: birkaç vaat oranını çok seed ile koşturur, çöküş haftasının
/// medyanını ve zirve yatırımcı sayısını basar. Denge değişince ilk bakılan yer.
void _runSweep(Map<String, String> flags) {
  final content = _findContentDir();
  final cfg = BalanceConfig.fromJsonString(
    File('${content.path}/balance.json').readAsStringSync(),
  );
  final events = EventEngine(const []); // Olaysız taban: saf ekonomi.
  final schemes = _loadSchemes(content);
  final seeds = int.parse(flags['seeds'] ?? '30');
  final weeks = int.parse(flags['weeks'] ?? '520');
  final only = flags['scheme'];
  stdout.writeln(
    'Tarama | $seeds seed | en fazla $weeks hafta | olaysız, pasif oyuncu',
  );
  for (final type in schemes) {
    if (only != null && type.id != only) continue;
    stdout.writeln('');
    stdout.writeln('${type.name} (${type.id})');
    stdout.writeln(
      'vaat/hafta | ~aylık | çöküş medyan | min-max  | ayakta | zirve yatırımcı | zirve ekstre | cep medyan',
    );
    _sweepScheme(cfg, events, type, seeds, weeks);
  }
}

void _sweepScheme(
  BalanceConfig cfg,
  EventEngine events,
  SchemeType type,
  int seeds,
  int weeks,
) {
  final rates = [
    type.startRateWeekly * 0.5,
    type.startRateWeekly,
    type.startRateWeekly * 2,
    type.startRateWeekly * 4,
    type.maxRateWeekly,
  ];
  for (final rate in rates) {
    final collapses = <int>[];
    var alive = 0;
    final peaks = <int>[];
    final peakPromised = <double>[];
    final pockets = <double>[];
    for (var seed = 1; seed <= seeds; seed++) {
      final rng = SimRng(seed);
      var state = SchemeState.initial(
        type: type,
        cash: type.startCash,
        seedInvestors: 10,
        seedTicket: cfg.segments[type.seedSegment]!.ticket,
        promisedRateWeekly: rate,
      );
      var peak = 0;
      var peakP = 0.0;
      for (var w = 0; w < weeks && !state.isOver; w++) {
        state = tick(state, const [], rng, cfg, events, type).state;
        if (state.investorCount > peak) peak = state.investorCount;
        if (state.promisedTotal > peakP) peakP = state.promisedTotal;
      }
      if (state.isOver) {
        collapses.add(state.week);
      } else {
        alive++;
      }
      peaks.add(peak);
      peakPromised.add(peakP);
      pockets.add(state.totalSkimmed);
    }
    collapses.sort();
    peaks.sort();
    peakPromised.sort();
    pockets.sort();
    final median = collapses.isEmpty
        ? '-'
        : collapses[collapses.length ~/ 2].toString();
    final range = collapses.isEmpty
        ? '-'
        : '${collapses.first}-${collapses.last}';
    stdout.writeln(
      '${(rate * 100).toStringAsFixed(1).padLeft(9)}% | '
      '${(rate * 433).toStringAsFixed(1).padLeft(5)}% | '
      '${median.padLeft(12)} | '
      '${range.padLeft(8)} | '
      '${alive.toString().padLeft(6)} | '
      '${peaks[peaks.length ~/ 2].toString().padLeft(15)} | '
      '${_money(peakPromised[peakPromised.length ~/ 2]).padLeft(12)} | '
      '${_money(pockets[pockets.length ~/ 2])}',
    );
  }
}

/// Basit stratejilerle oynayan botlar. Denge turunun asıl ölçüsü bu: pasif
/// koşu şemanın kendi kendine ne kadar dayandığını gösterir, bot koşusu
/// oyuncunun gerçekten bir şey kazanıp kazanamadığını.
void _runStrategy(Map<String, String> flags) {
  final content = _findContentDir();
  final cfg = BalanceConfig.fromJsonString(
    File('${content.path}/balance.json').readAsStringSync(),
  );
  final defs = <EventDef>[];
  for (final f in Directory('${content.path}/events').listSync()) {
    if (f is File && f.path.endsWith('.json')) {
      defs.addAll(EventDef.listFromJsonString(f.readAsStringSync()));
    }
  }
  final events = EventEngine(defs);
  final schemes = _loadSchemes(content);
  final seeds = int.parse(flags['seeds'] ?? '20');
  final only = flags['scheme'];

  final bots = <String, _Bot>{
    'pasif': _passiveBot,
    'açgözlü': _greedyBot,
    'temkinli': _cautiousBot,
    'borsacı': _traderBot,
  };

  stdout.writeln('Strateji turu | $seeds seed | olaylar açık');
  for (final type in schemes) {
    if (only != null && type.id != only) continue;
    stdout.writeln('');
    stdout.writeln(type.name);
    stdout.writeln('bot        | medyan hafta | medyan cep | medyan kasa | bitiş');
    for (final entry in bots.entries) {
      final weeks = <int>[];
      final pockets = <double>[];
      final cashes = <double>[];
      final ends = <String, int>{};
      for (var seed = 1; seed <= seeds; seed++) {
        final r = _playBot(entry.value, type, cfg, events, seed);
        weeks.add(r.$1);
        pockets.add(r.$2);
        cashes.add(r.$3);
        ends[r.$4] = (ends[r.$4] ?? 0) + 1;
      }
      weeks.sort();
      pockets.sort();
      cashes.sort();
      final top = ends.entries.reduce((a, b) => a.value >= b.value ? a : b);
      stdout.writeln(
        '${entry.key.padRight(10)} | '
        '${weeks[weeks.length ~/ 2].toString().padLeft(12)} | '
        '${_money(pockets[pockets.length ~/ 2]).padLeft(10)} | '
        '${_money(cashes[cashes.length ~/ 2]).padLeft(11)} | '
        '${top.key} (${top.value}/$seeds)',
      );
    }
  }
}

typedef _Bot = List<PlayerAction> Function(SchemeState s, SchemeType t);

/// Botu bir kariyer bölümü boyunca koşturur; kaçış kararını da bot verir.
(int, double, double, String) _playBot(
  _Bot bot,
  SchemeType type,
  BalanceConfig cfg,
  EventEngine events,
  int seed,
) {
  final rng = SimRng(seed);
  var s = SchemeState.initial(
    type: type,
    cash: type.startCash,
    seedInvestors: 10,
    seedTicket: cfg.segments[type.seedSegment]!.ticket,
  );
  for (var w = 0; w < 700 && !s.isOver; w++) {
    s = tick(s, bot(s, type), rng, cfg, events, type).state;
  }
  return (s.week, s.totalSkimmed, s.cash, s.end?.name ?? 'ayakta');
}

List<PlayerAction> _passiveBot(SchemeState s, SchemeType t) => const [];

/// Tavan vaat, yüksek skim, sonuna kadar. Hızlı yükselen ve hızlı düşen oyun.
List<PlayerAction> _greedyBot(SchemeState s, SchemeType t) {
  final actions = <PlayerAction>[];
  if (s.week == 1) {
    actions.add(SetPromisedRate(t.maxRateWeekly));
    // Gerçek vakalarda operatörün cebe attığı medyan pay %13; açgözlü bot
    // bunun iki katını alıyor ama %30 gibi bir oran kasayı hiç doldurmuyordu.
    actions.add(const SetSkim(0.26));
  }
  for (final seg in s.segments.entries) {
    if (!seg.value.open) actions.add(OpenSegment(seg.key));
  }
  if (s.week % 6 == 0) actions.add(const Marketing(200000));
  return actions;
}

/// Düşük vaat, düşük skim, karşılama düşünce kaç. "Madoff yolu".
List<PlayerAction> _cautiousBot(SchemeState s, SchemeType t) {
  final actions = <PlayerAction>[];
  if (s.week == 1) {
    actions.add(SetPromisedRate(t.startRateWeekly * 0.8));
    actions.add(const SetSkim(0.08));
  }
  // Masadan kalkma eşiği: karşılama oranı zaten doğal olarak hızla düşüyor,
  // %25 eşiği botu daha ikinci ayda kaçırıyordu. Asıl tehlike şüphe.
  if (s.week > 30 && (s.coverage < 0.10 || s.suspicion > 78)) {
    return [const Flee()];
  }
  if (s.week % 12 == 0) actions.add(const Marketing(60000));
  return actions;
}

/// Borsa şemasında pompala ve boşalt döngüsü; diğer şemalarda temkinli gibi.
List<PlayerAction> _traderBot(SchemeState s, SchemeType t) {
  if (!s.board.isActive) return _cautiousBot(s, t);
  final actions = <PlayerAction>[];
  if (s.week == 1) actions.add(const SetSkim(0.12));
  if (s.week > 30 && (s.coverage < 0.10 || s.suspicion > 82)) {
    return [const Flee()];
  }

  // En sakin kâğıdı seç: iz düşük olan en az dikkat çeker.
  final stocks = [...s.board.stocks]..sort((a, b) => a.heat.compareTo(b.heat));
  final target = stocks.first;

  // Üç haftalık döngü: topla, pompala, tepede boşalt.
  switch (s.week % 3) {
    case 0:
      final lots = (s.cash * 0.25 / target.price).floor();
      if (lots > 0) actions.add(BuyStock(target.id, lots));
    case 1:
      final hot = s.board.stocks.where((x) => x.shares > 0);
      if (hot.isNotEmpty) {
        actions.add(
            ManipulateStock(hot.first.id, Manipulation.pumpAndDump));
      }
    case 2:
      for (final x in s.board.stocks) {
        if (x.shares > 0) actions.add(SellStock(x.id, x.shares));
      }
  }
  return actions;
}

void _runVerify() {
  stdout.writeln('Tasarım dokümanındaki aylık çöküş tablosu (basit model)');
  stdout.writeln('vaat  | çekim | büyüme            | doküman | model');
  final rows = <(double, double, double, int?, String, String)>[
    (0.05, 0.02, 0.10, null, '%10 sınırsız', 'çökmez'),
    (0.05, 0.02, 0.10, 24, '%10, 24. ayda plato', '68'),
    (0.05, 0.02, 0.03, null, '%3', '76'),
    (0.05, 0.02, 0.00, null, '%0 sabit', '55'),
    (0.05, 0.05, 0.00, null, '%0', '41'),
    (0.10, 0.03, 0.05, null, '%5', '40'),
    (0.03, 0.01, 0.02, null, '%2', '143'),
    (0.01, 0.01, 0.00, null, '%0', '201'),
    (0.01, 0.01, -0.05, null, 'eksi %5 kriz', '120'),
  ];
  for (final (rp, rw, g, plateau, label, expected) in rows) {
    final months = monthsToCollapse(
      promisedMonthly: rp,
      withdrawMonthly: rw,
      inflowGrowthMonthly: g,
      plateauMonth: plateau,
    );
    stdout.writeln(
      '${(rp * 100).toStringAsFixed(0).padLeft(4)}% | '
      '${(rw * 100).toStringAsFixed(0).padLeft(4)}% | '
      '${label.padRight(17)} | '
      '${expected.padLeft(7)} | '
      '${months?.toString() ?? 'çökmez'}',
    );
  }
}

String _money(double v) {
  final abs = v.abs();
  final sign = v < 0 ? '-' : '';
  if (abs >= 1e9) return '$sign${(abs / 1e9).toStringAsFixed(2)} mr';
  if (abs >= 1e6) return '$sign${(abs / 1e6).toStringAsFixed(2)} mn';
  if (abs >= 1e3) return '$sign${(abs / 1e3).toStringAsFixed(0)} bin';
  return '$sign${abs.toStringAsFixed(0)}';
}
