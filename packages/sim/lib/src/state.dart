import 'market.dart';
import 'scheme_type.dart';
import 'stocks.dart';

/// Bir segmentin canlı durumu.
class SegmentState {
  const SegmentState({
    required this.investors,
    required this.promised,
    required this.open,
  });

  const SegmentState.closed()
      : investors = 0,
        promised = 0,
        open = false;

  /// Aktif yatırımcı sayısı.
  final int investors;

  /// Bu segmentin ekstrelerinde yazan toplam bakiye. Gerçek para değil, vaat.
  final double promised;

  /// Kanal açık mı. Kapalı segmentten yeni para gelmez.
  final bool open;

  SegmentState copyWith({int? investors, double? promised, bool? open}) =>
      SegmentState(
        investors: investors ?? this.investors,
        promised: promised ?? this.promised,
        open: open ?? this.open,
      );
}

/// Zamanla sönen çarpan. Ünlü reklamı, kriz, kilit süresi gibi etkiler.
class TimedModifier {
  const TimedModifier({
    required this.kind,
    required this.multiplier,
    required this.weeksLeft,
  });

  final ModifierKind kind;
  final double multiplier;
  final int weeksLeft;

  TimedModifier tickDown() => TimedModifier(
        kind: kind,
        multiplier: multiplier,
        weeksLeft: weeksLeft - 1,
      );
}

enum ModifierKind { channel, withdraw }

/// Şemanın nasıl bittiği. `null` ise hâlâ ayakta.
enum SchemeEnd {
  /// Ödeme yapılamadı, toplu çekim havuzu boşalttı. Kariyer biter.
  bankRun,

  /// Şüphe barı doldu, baskın. Kariyer biter.
  raid,

  /// Oyuncu kaçtı. Para gelir, yüz tanınır.
  fled,

  /// Firma alıcıya satıldı. Az para, temiz para, az iz.
  sold,

  /// Firma bir ortağa veya çalışana devredildi. Suç onda kalır, ama konuşabilir.
  handedOver,
}

/// Bölüm sonunun kariyere ne taşıdığı.
extension SchemeEndTraits on SchemeEnd {
  /// Kariyeri bitiren sonlar. Diğerlerinden sonra oyuncu yoluna devam eder.
  bool get endsCareer => this == SchemeEnd.bankRun || this == SchemeEnd.raid;
}

/// Bir şemanın tam durumu. Değişmez; her tur yeni bir örnek üretir.
///
/// Neden değişmez: geri alma yok ama her turun state'i kayıt dosyasına
/// olduğu gibi yazılır, UI eski ve yeni state'i yan yana koyup animasyon üretir.
class SchemeState {
  const SchemeState({
    required this.typeId,
    required this.week,
    required this.market,
    required this.board,
    required this.cash,
    required this.segments,
    required this.promisedRateWeekly,
    required this.skim,
    required this.fixedCostWeekly,
    required this.panic,
    required this.missedPayments,
    required this.bankRun,
    required this.suspicion,
    required this.totalInflow,
    required this.totalPaidOut,
    required this.totalSkimmed,
    required this.modifiers,
    required this.pendingEventIds,
    required this.firedEventIds,
    this.eventChoices = const {},
    required this.end,
    required this.endReason,
  });

  /// Yeni şema. `seedSegment` içindeki `seedInvestors` kişi "kabile":
  /// ilk parayı koyanlar, sosyal kanıtın başlangıcı.
  factory SchemeState.initial({
    required SchemeType type,
    required double cash,
    required int seedInvestors,
    required double seedTicket,
    double? promisedRateWeekly,
    double skim = 0.13,
    double startingSuspicion = 0,
  }) {
    final segments = {
      for (final id in type.segments) id: const SegmentState.closed(),
    };
    segments[type.seedSegment] = SegmentState(
      investors: seedInvestors,
      promised: seedInvestors * seedTicket,
      open: true,
    );
    return SchemeState(
      typeId: type.id,
      week: 0,
      market: const MarketState.initial(),
      board: type.stocks.isEmpty
          ? const StockBoard.empty()
          : StockBoard.create(type.stocks),
      cash: cash + seedInvestors * seedTicket,
      segments: segments,
      promisedRateWeekly: promisedRateWeekly ?? type.startRateWeekly,
      skim: skim,
      fixedCostWeekly: type.fixedCostWeekly,
      panic: 1.0,
      missedPayments: 0,
      bankRun: false,
      // Geçmiş dosyası ağırsa yeni şema sıfırdan başlamaz: adın zaten geçiyor.
      suspicion: startingSuspicion,
      totalInflow: seedInvestors * seedTicket,
      totalPaidOut: 0,
      totalSkimmed: 0,
      modifiers: const [],
      pendingEventIds: const [],
      firedEventIds: const {},
      end: null,
      endReason: null,
    );
  }

  /// Oynanan şema türünün id'si. Tür tanımı `content/schemes.json`'da.
  final String typeId;

  final int week;

  /// Piyasanın genel havası. Şemadan bağımsız, ama akışı ve çekimi belirler.
  final MarketState market;

  /// Hisse tahtası. Yalnız borsa oynatılan şemalarda dolu.
  final StockBoard board;

  /// Gerçek kasa. HUD'daki tek "doğru" sayı.
  final double cash;

  final Map<String, SegmentState> segments;

  /// Oyuncunun ayarladığı haftalık vaat.
  final double promisedRateWeekly;

  /// Gelen paradan oyuncunun cebe attığı pay. Gerçek vakalarda medyan %13.
  final double skim;

  /// Ofis, ekip, lüks, rüşvet: her hafta otomatik düşer.
  final double fixedCostWeekly;

  /// Panik çarpanı, 1,0 sakin. Gecikmiş ödeme kalıcı yükseltir, yavaş söner.
  final double panic;

  final int missedPayments;

  /// İkinci gecikmeden sonra doğru: çekimler beş kat, bir sonraki gecikme çöküş.
  final bool bankRun;

  /// 0 ile 100. Eşiği aşınca baskın.
  final double suspicion;

  final double totalInflow;
  final double totalPaidOut;

  /// Oyuncunun kişisel cebi. Kaçışta yanına aldığı para buradan ve kasadan.
  final double totalSkimmed;

  final List<TimedModifier> modifiers;

  /// Bu hafta oyuncunun önüne düşen, henüz cevaplanmamış olaylar.
  final List<String> pendingEventIds;

  /// Bu şemada bir kez tetiklenen olaylar. Aynı olay iki kez gelmez.
  final Set<String> firedEventIds;

  /// Hangi olayda hangi seçeneğin hangi hafta seçildiği. Zincirli kartlar
  /// buna bakar: reklam yüzüyle anlaştıysan skandalı da o getirir.
  final Map<String, EventChoice> eventChoices;

  final SchemeEnd? end;
  final String? endReason;

  bool get isOver => end != null;

  /// Ekstrelerde yazan toplam. Yatırımcıların "sahip olduklarını sandığı" para.
  double get promisedTotal =>
      segments.values.fold(0.0, (sum, s) => sum + s.promised);

  int get investorCount =>
      segments.values.fold(0, (sum, s) => sum + s.investors);

  /// Karşılama oranı S/P. %100 üstü meşru fon, %20 altı bir kötü haberle çöküş.
  double get coverage => promisedTotal <= 0 ? 1 : cash / promisedTotal;

  /// Delik: yatırımcıların sandığı ile kasadaki arasındaki fark.
  double get hole => promisedTotal - cash;

  double channelMultiplier() => _multiplierFor(ModifierKind.channel);

  double withdrawMultiplier() => _multiplierFor(ModifierKind.withdraw);

  double _multiplierFor(ModifierKind kind) => modifiers
      .where((m) => m.kind == kind)
      .fold(1.0, (product, m) => product * m.multiplier);

  SchemeState copyWith({
    String? typeId,
    int? week,
    MarketState? market,
    StockBoard? board,
    double? cash,
    Map<String, SegmentState>? segments,
    double? promisedRateWeekly,
    double? skim,
    double? fixedCostWeekly,
    double? panic,
    int? missedPayments,
    bool? bankRun,
    double? suspicion,
    double? totalInflow,
    double? totalPaidOut,
    double? totalSkimmed,
    List<TimedModifier>? modifiers,
    List<String>? pendingEventIds,
    Set<String>? firedEventIds,
    Map<String, EventChoice>? eventChoices,
    SchemeEnd? end,
    String? endReason,
  }) =>
      SchemeState(
        typeId: typeId ?? this.typeId,
        week: week ?? this.week,
        market: market ?? this.market,
        board: board ?? this.board,
        cash: cash ?? this.cash,
        segments: segments ?? this.segments,
        promisedRateWeekly: promisedRateWeekly ?? this.promisedRateWeekly,
        skim: skim ?? this.skim,
        fixedCostWeekly: fixedCostWeekly ?? this.fixedCostWeekly,
        panic: panic ?? this.panic,
        missedPayments: missedPayments ?? this.missedPayments,
        bankRun: bankRun ?? this.bankRun,
        suspicion: suspicion ?? this.suspicion,
        totalInflow: totalInflow ?? this.totalInflow,
        totalPaidOut: totalPaidOut ?? this.totalPaidOut,
        totalSkimmed: totalSkimmed ?? this.totalSkimmed,
        modifiers: modifiers ?? this.modifiers,
        pendingEventIds: pendingEventIds ?? this.pendingEventIds,
        firedEventIds: firedEventIds ?? this.firedEventIds,
        eventChoices: eventChoices ?? this.eventChoices,
        end: end ?? this.end,
        endReason: endReason ?? this.endReason,
      );
}

/// Bir olay kartına verilen cevap. Cevapsız kalan kart da buraya son
/// seçenekle düşer, çünkü görmezden gelmek de bir karardır.
class EventChoice {
  const EventChoice({required this.option, required this.week});

  final int option;
  final int week;
}
