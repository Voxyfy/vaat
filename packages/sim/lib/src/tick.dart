import 'dart:math' as math;

import 'actions.dart';
import 'balance.dart';
import 'events.dart';
import 'market.dart';
import 'career.dart';
import 'rng.dart';
import 'stocks.dart';
import 'scheme_type.dart';
import 'state.dart';

/// Kariyerin bölüm içine taşıdığı kalıcı etkiler.
///
/// Neden ayrı sınıf: tick'in kariyer state'ini tanıması gerekmiyor, yalnız
/// birkaç çarpan lazım. Böylece simülasyon çekirdeği kariyer kurallarından
/// bağımsız kalıyor ve tek başına test edilebiliyor.
class CareerModifiers {
  const CareerModifiers({
    this.suspicionShield = 1.0,
    this.channelBonus = 1.0,
    this.weeklyIncome = 0,
    this.launderPerWeek = 0,
    this.partnerCut = 0,
    this.events = EventContext.none,
  });

  /// Şüphe birikimine çarpan. 1'in altı koruma demek.
  final double suspicionShield;

  /// Yeni para akışına çarpan.
  final double channelBonus;

  /// İşletmelerden gelen haftalık net kâr veya zarar.
  final double weeklyIncome;

  /// Haftada temize çevrilebilen kara para.
  final double launderPerWeek;

  /// Ortağın cepten aldığı pay.
  final double partnerCut;

  /// Olay kartlarının baktığı kariyer bilgisi: hangi işler ve kimler var.
  final EventContext events;
}

/// Bir haftanın sonucu: yeni state ve UI'nın animasyona çevireceği kayıt.
class TickResult {
  const TickResult({
    required this.state,
    required this.log,
    required this.inflow,
    required this.withdrawDemand,
    required this.paidOut,
    required this.newEvents,
    this.laundered = 0,
  });

  final SchemeState state;
  final List<String> log;
  final double inflow;
  final double withdrawDemand;
  final double paidOut;
  final List<EventDef> newEvents;

  /// Bu hafta temize çevrilen kara para.
  final double laundered;
}

/// Simülasyonun tek giriş noktası. Bir hafta ilerletir.
///
/// Sıra: hamleler, ekstre faizi, çekim talebi, yeni para, kasa, ekstre,
/// şüphe, çöküş kontrolü, sönen etkiler, yeni olaylar. Bu sıra tasarım
/// dokümanındaki modelle aynı; değiştirilirse denge tablosu geçersiz olur.
TickResult tick(
  SchemeState start,
  List<PlayerAction> actions,
  SimRng rng,
  BalanceConfig cfg,
  EventEngine events,
  SchemeType type, {
  CareerModifiers career = const CareerModifiers(),
}) {
  if (start.isOver) {
    return TickResult(
      state: start,
      log: const ['Şema bitti.'],
      inflow: 0,
      withdrawDemand: 0,
      paidOut: 0,
      newEvents: const [],
    );
  }

  final log = <String>[];
  var s = start;
  var marketingSpend = 0.0;
  var oneWeekChannelMult = 1.0;

  // 1. Hamleler.
  for (final action in actions) {
    switch (action) {
      case SetPromisedRate(:final rateWeekly):
        s = s.copyWith(
            promisedRateWeekly: rateWeekly.clamp(0.0, type.maxRateWeekly));
      case SetSkim(:final skim):
        s = s.copyWith(skim: skim.clamp(0.0, 0.9));
      case OpenSegment(:final segmentId, :final setupCost):
        final seg = s.segments[segmentId];
        if (seg != null && !seg.open) {
          final segments = {...s.segments};
          segments[segmentId] = seg.copyWith(open: true);
          // Kanal açmak gider ve dikkat çeker: yeni bir kalabalığa
          // el sallıyorsun.
          s = s.copyWith(
            segments: segments,
            cash: s.cash - setupCost,
            suspicion: (s.suspicion + 3).clamp(0, 100),
          );
          log.add('${cfg.segments[segmentId]?.name ?? segmentId} kanalı açıldı.');
        }
      case BuyStock(:final stockId, :final shares):
        s = _trade(s, stockId, shares, log, buy: true);
      case SellStock(:final stockId, :final shares):
        s = _trade(s, stockId, shares, log, buy: false);
      case ManipulateStock(:final stockId, :final kind):
        s = _manipulate(s, stockId, kind, log);
      case Marketing(:final amount):
        marketingSpend += amount;
        // Logaritmik getiri: ikinci 100 bin ilk 100 bin kadar iş yapmaz.
        oneWeekChannelMult += math.log(1 + amount / 50000);
      case ResolveEvent(:final eventId, :final optionIndex):
        s = _resolveEvent(s, events, eventId, optionIndex, log);
      case Flee():
        return _finish(s, SchemeEnd.fled,
            'Kurucu ${s.week}. haftada ortadan kayboldu.', log, 'Kaçış.');
      case SellScheme():
        // Kosul tutmuyorsa hamle bosa gider ama sessiz kalmaz: oyuncu neden
        // satamadigini gormeli.
        if (canSell(s, type)) {
          return _finish(s, SchemeEnd.sold,
              'Firma ${s.week}. haftada satıldı.', log, 'Satış tamam.');
        }
        log.add('Alıcı defterlere baktı ve masadan kalktı.');
      case HandOverScheme():
        if (canHandOver(s)) {
          return _finish(s, SchemeEnd.handedOver,
              'Firma ${s.week}. haftada devredildi.', log, 'Devir tamam.');
        }
        log.add('Bu firmayı devralacak kimse bulunamadı.');
    }
  }

  // Cevaplanmamış olaylar son seçenekle kapanır. "Görmezden gelmek" de bir
  // karardır; seçenek listeleri buna göre yazılır, son seçenek pasif olandır.
  for (final id in [...s.pendingEventIds]) {
    final def = events.byId(id);
    if (def == null) continue;
    s = _resolveEvent(s, events, id, def.options.length - 1, log,
        auto: true);
  }

  final week = s.week + 1;
  final rp = s.promisedRateWeekly;

  // Piyasa önce ilerler: bu haftanın akışı ve çekimi onun havasına göre.
  final market = stepMarket(s.market, rng);
  final board = stepStocks(s.board, market, rng);
  // Duyarlılık çarpanı 1'den uzaklaştıkça etki büyür veya söner.
  double marketEffect(double raw) =>
      1 + (raw - 1) * type.marketSensitivity;

  // 2. Ekstrelerde faiz işler. Para yok, rakam var.
  var segments = <String, SegmentState>{};
  for (final entry in s.segments.entries) {
    segments[entry.key] = entry.value.copyWith(
      promised: entry.value.promised * (1 + rp),
    );
  }

  // 3. Çekim talebi. Panik segment hassasiyetiyle çarpılır, bank run her
  // şeyi katlar.
  final withdrawBase = cfg.baseWithdrawWeekly *
      type.withdrawMult *
      marketEffect(market.withdrawMultiplier) *
      s.withdrawMultiplier() *
      (s.bankRun ? cfg.panic.bankRunMultiplier : 1.0);
  final demandBySegment = <String, double>{};
  var totalDemand = 0.0;
  for (final entry in segments.entries) {
    final segCfg = cfg.segments[entry.key]!;
    final panicEffect = 1 + (s.panic - 1) * segCfg.panicMult;
    final rate = (withdrawBase * segCfg.withdrawMult * panicEffect).clamp(0.0, 1.0);
    final demand = entry.value.promised * rate;
    demandBySegment[entry.key] = demand;
    totalDemand += demand;
  }

  // 4. Yeni para. Lojistik: boş havuz kadar ve sosyal kanıt kadar.
  final channelMult = type.channelMult *
      career.channelBonus *
      marketEffect(market.inflowMultiplier) *
      s.channelMultiplier() *
      oneWeekChannelMult;
  final inflowBySegment = <String, double>{};
  final newInvestorsBySegment = <String, int>{};
  var totalInflow = 0.0;
  for (final entry in segments.entries) {
    final seg = entry.value;
    if (!seg.open) continue;
    final segCfg = cfg.segments[entry.key]!;
    final remaining = segCfg.market - seg.investors;
    if (remaining <= 0) continue;

    final socialProof = math.max(seg.investors, cfg.inflow.socialProofFloor);
    final appeal = math
        .pow(rp / cfg.referenceRateWeekly, cfg.inflow.rateAppealExponent)
        .toDouble()
        .clamp(cfg.inflow.rateAppealMin, cfg.inflow.rateAppealMax);
    // Vaat, segmentin inanabileceğinin üstündeyse "fazla iyi" etkisi:
    // emekli %5 haftalığa inanır, kurumsal fon inanmaz.
    final excess = rp - segCfg.maxCredibleRateWeekly;
    final credibility = excess <= 0
        ? 1.0
        : math.exp(-cfg.inflow.credibilityFalloff *
            excess /
            segCfg.maxCredibleRateWeekly);
    final expected = segCfg.channelBase *
        channelMult *
        remaining *
        socialProof /
        segCfg.market *
        appeal *
        credibility;
    final newInvestors = math.min(rng.stochasticRound(expected), remaining);
    newInvestorsBySegment[entry.key] = newInvestors;
    final money = newInvestors * segCfg.ticket;
    inflowBySegment[entry.key] = money;
    totalInflow += money;
  }

  // 5. Kasa. Gelen paradan skim düşer, sabit gider ve pazarlama düşer,
  // kalanla çekimler ödenir.
  // Ortak kârdan pay alır: cebe giren azalır ama kasadan çıkmaz.
  final skimmed = totalInflow * s.skim * (1 - career.partnerCut);
  final partnerTake = totalInflow * s.skim * career.partnerCut;
  var available = s.cash * (1 + cfg.realReturnWeekly) +
      totalInflow -
      skimmed -
      partnerTake -
      s.fixedCostWeekly -
      marketingSpend +
      // İşletmeler kazandırır veya yer; futbol kulübü her hafta para yer.
      career.weeklyIncome;
  final paid = math.min(math.max(available, 0.0), totalDemand);
  final unpaid = totalDemand - paid;
  var cash = available - paid;

  var panic = s.panic;
  var suspicion = s.suspicion;
  var missed = s.missedPayments;
  var bankRun = s.bankRun;
  SchemeEnd? end;
  String? endReason;

  if (unpaid > 1) {
    missed += 1;
    panic += cfg.panic.missedPaymentStep;
    suspicion += cfg.suspicion.missedPayment * type.suspicionMult;
    log.add('Ödeme gecikti: ${_fmt(unpaid)} ödenemedi.');
    if (bankRun) {
      end = SchemeEnd.bankRun;
      endReason = 'Toplu çekim sırasında ödeme yapılamadı, $week. hafta.';
    } else if (missed >= 2) {
      bankRun = true;
      suspicion += cfg.suspicion.bankRun;
      log.add('Toplu çekim başladı.');
    }
  } else if (bankRun) {
    // Bank run sırasında ödemeyi yetiştirdin: kalabalık dağılmaz ama
    // en azından bugün ölmedin. Panik yavaş yavaş söner.
    log.add('Toplu çekim ödendi, kalabalık hâlâ kapıda.');
  }

  // 6. Ekstre güncellenir: ödenen kadar düşer, yeni para eklenir.
  // Ödenmeyen çekim ekstrede kalır, yatırımcı hâlâ alacaklı sanır.
  for (final entry in segments.entries) {
    final seg = entry.value;
    final demand = demandBySegment[entry.key] ?? 0;
    final share = totalDemand > 0 ? demand / totalDemand : 0.0;
    final paidHere = paid * share;
    final inflowHere = inflowBySegment[entry.key] ?? 0;
    // Parasını tam çeken yatırımcı ayrılır. Ödenen oran kadar kişi gider.
    final leaving = seg.promised > 0
        ? (seg.investors * (paidHere / seg.promised)).floor()
        : 0;
    segments[entry.key] = seg.copyWith(
      promised: math.max(seg.promised - paidHere + inflowHere, 0.0),
      investors: math.max(
          seg.investors - leaving + (newInvestorsBySegment[entry.key] ?? 0), 0),
    );
  }

  // 7. Şüphe. Aşırı vaat her hafta damlatır, pazarlama dikkat çeker,
  // zaman biraz unutturur.
  // Aşırı vaat, görünürlükle çarpılır: 30 kişilik bir grup %5 vaat etse kimse
  // duymaz, 30 bin kişilik grup etse gazeteci hesap makinesini alır.
  final rateExcess = math.max(0.0, rp - cfg.referenceRateWeekly);
  final visibility = math.log(1 + _investorCount(segments)) / math.ln10 / 4;
  suspicion +=
      rateExcess * cfg.suspicion.rateExcessPerUnit * visibility * type.suspicionMult;
  suspicion += marketingSpend / 1000 * cfg.suspicion.marketingPerThousand;
  // Borsadaki iz: denetleyici en sıcak kâğıda bakar. İşlem kalıpları
  // yakalanabilir, bu yüzden manipülasyon şüpheyi sürekli besler.
  if (board.isActive) {
    suspicion += board.maxHeat * 0.04 * type.suspicionMult;
  }
  // Kariyer kalkanı: paravan işletmeler ve tanıdıklar şüpheyi yavaşlatır.
  // Kalkan yalnız bu hafta eklenene uygulanır, birikmiş şüpheye değil.
  final gained = suspicion - s.suspicion;
  if (gained > 0) {
    suspicion = s.suspicion + gained * career.suspicionShield;
  }
  suspicion -= cfg.suspicion.decayPerWeek;
  suspicion = suspicion.clamp(0.0, 100.0);

  if (end == null && suspicion >= cfg.suspicion.raidThreshold) {
    end = SchemeEnd.raid;
    endReason = 'Şüphe barı doldu, baskın. $week. hafta.';
  }

  // 8. Panik yavaş söner, pazarlama biraz sakinleştirir.
  panic = math.max(
    1.0,
    panic -
        cfg.panic.decayPerWeek -
        (marketingSpend > 0 ? cfg.panic.marketingRelief : 0),
  );

  // 9. Sönen etkiler.
  final modifiers = [
    for (final m in s.modifiers)
      if (m.weeksLeft > 1) m.tickDown(),
  ];

  var next = s.copyWith(
    week: week,
    market: market,
    board: board,
    cash: cash,
    segments: segments,
    panic: panic,
    missedPayments: missed,
    bankRun: bankRun,
    suspicion: suspicion,
    totalInflow: s.totalInflow + totalInflow,
    totalPaidOut: s.totalPaidOut + paid,
    totalSkimmed: s.totalSkimmed + skimmed,
    modifiers: modifiers,
    pendingEventIds: const [],
    end: end,
    endReason: endReason,
  );

  // 10. Yeni olaylar. Bitmiş şemaya kart düşmez.
  var newEvents = const <EventDef>[];
  if (!next.isOver) {
    newEvents = events.draw(next, rng, career.events);
    if (newEvents.isNotEmpty) {
      next = next.copyWith(
        pendingEventIds: [for (final e in newEvents) e.id],
        firedEventIds: {...next.firedEventIds, for (final e in newEvents) e.id},
      );
      for (final e in newEvents) {
        log.add('Olay: ${e.title}');
      }
    }
  }

  return TickResult(
    state: next,
    log: log,
    inflow: totalInflow,
    withdrawDemand: totalDemand,
    paidOut: paid,
    newEvents: newEvents,
    laundered: career.launderPerWeek,
  );
}

/// Bölümü kapatan sonlar aynı işi yapıyor: state'i mühürle, boş bir tur döndür.
TickResult _finish(
  SchemeState s,
  SchemeEnd end,
  String reason,
  List<String> log,
  String line,
) =>
    TickResult(
      state: s.copyWith(
        end: end,
        endReason: reason,
        pendingEventIds: const [],
      ),
      log: [...log, line],
      inflow: 0,
      withdrawDemand: 0,
      paidOut: 0,
      newEvents: const [],
    );

/// Hisse alım satımı. Kasada para yoksa veya elde lot yoksa hamle boşa gider
/// ama sessiz kalmaz.
SchemeState _trade(
  SchemeState s,
  String stockId,
  int shares,
  List<String> log, {
  required bool buy,
}) {
  final stock = s.board.byId(stockId);
  if (stock == null || shares <= 0) return s;

  if (buy) {
    final cost = stock.price * shares;
    if (cost > s.cash) {
      log.add('${stock.name}: alım için kasada yeterli para yok.');
      return s;
    }
    final total = stock.shares + shares;
    // Ortalama maliyet: kâr zarar bunun üzerinden hesaplanıyor.
    final avg = (stock.avgCost * stock.shares + cost) / total;
    return _replaceStock(
      s.copyWith(cash: s.cash - cost),
      stock.copyWith(shares: total, avgCost: avg),
    );
  }

  final sold = math.min(shares, stock.shares);
  if (sold <= 0) {
    log.add('${stock.name}: satılacak lot yok.');
    return s;
  }
  final proceeds = stock.price * sold;
  final rest = stock.shares - sold;
  return _replaceStock(
    s.copyWith(cash: s.cash + proceeds),
    stock.copyWith(shares: rest, avgCost: rest == 0 ? 0 : stock.avgCost),
  );
}

/// Manipülasyon: fiyatı anında iter, izi artırır, sönme kaydı bırakır.
SchemeState _manipulate(
  SchemeState s,
  String stockId,
  Manipulation kind,
  List<String> log,
) {
  final stock = s.board.byId(stockId);
  if (stock == null) return s;
  final cost = stock.manipulationCost * kind.cashFactor;
  if (cost > s.cash) {
    log.add('${stock.name}: bu operasyon için kasa yetmiyor.');
    return s;
  }

  final kick = kind.priceKick;
  final bumped = stock.copyWith(
    price: stock.price * (1 + kick),
    heat: (stock.heat + kind.heatCost).clamp(0, 100),
  );
  final board = s.board.copyWith(
    stocks: [
      for (final x in s.board.stocks) x.id == stock.id ? bumped : x,
    ],
    // Şişen fiyat haftalar içinde geri çekilecek; ne zaman satacağın oyunun
    // asıl kararı.
    pending: [
      ...s.board.pending,
      PendingKick(
        stockId: stock.id,
        remaining: kick,
        weeksLeft: kind.decayWeeks,
      ),
    ],
  );
  return s.copyWith(cash: s.cash - cost, board: board);
}

SchemeState _replaceStock(SchemeState s, Stock updated) => s.copyWith(
      board: s.board.copyWith(
        stocks: [
          for (final x in s.board.stocks) x.id == updated.id ? updated : x,
        ],
      ),
    );

SchemeState _resolveEvent(
  SchemeState s,
  EventEngine events,
  String eventId,
  int optionIndex,
  List<String> log, {
  bool auto = false,
}) {
  if (!s.pendingEventIds.contains(eventId)) return s;
  final def = events.byId(eventId);
  if (def == null) return s;
  final index = optionIndex.clamp(0, def.options.length - 1);
  final option = def.options[index];
  log.add('${def.title}: ${option.label}${auto ? ' (cevapsız kaldı)' : ''}');
  final pending = [...s.pendingEventIds]..remove(eventId);
  return option.effects.applyTo(s).copyWith(
    pendingEventIds: pending,
    eventChoices: {
      ...s.eventChoices,
      eventId: EventChoice(option: index, week: s.week),
    },
  );
}

String _fmt(double v) => v.toStringAsFixed(0);

int _investorCount(Map<String, SegmentState> segments) =>
    segments.values.fold(0, (sum, s) => sum + s.investors);
