import 'dart:io';

import 'package:test/test.dart';
import 'package:vaat_sim/vaat_sim.dart';

BalanceConfig _cfg() => BalanceConfig.fromJsonString(
      File('../../content/balance.json').readAsStringSync(),
    );

List<SchemeType> _schemes() => SchemeType.listFromJsonString(
      File('../../content/schemes.json').readAsStringSync(),
    );

SchemeType _type(String id) => _schemes().firstWhere((t) => t.id == id);

SchemeState _fresh(BalanceConfig cfg, SchemeType t, {double? rate}) =>
    SchemeState.initial(
      type: t,
      cash: t.startCash,
      seedInvestors: 10,
      seedTicket: cfg.segments[t.seedSegment]!.ticket,
      promisedRateWeekly: rate,
    );

SchemeState _run(SchemeState s, int weeks, SimRng rng, BalanceConfig cfg,
    EventEngine ev, SchemeType t) {
  var state = s;
  for (var i = 0; i < weeks && !state.isOver; i++) {
    state = tick(state, const [], rng, cfg, ev, t).state;
  }
  return state;
}

void main() {
  final cfg = _cfg();
  final events = EventEngine(const []);

  test('her şema türü tanımlı segmentlerle açılır', () {
    for (final t in _schemes()) {
      final s = _fresh(cfg, t);
      expect(s.typeId, t.id);
      expect(s.segments.keys, containsAll(t.segments));
      expect(s.segments[t.seedSegment]!.open, isTrue,
          reason: '${t.id} kabile segmenti açık başlamalı');
      expect(s.promisedRateWeekly, t.startRateWeekly);
    }
  });

  test('her şema türü olaysız koşuda kendiliğinden çöker', () {
    for (final t in _schemes()) {
      final s = _run(_fresh(cfg, t), 1200, SimRng(4), cfg, events, t);
      expect(s.isOver, isTrue, reason: '${t.id} 1200 haftada bitmeliydi');
    }
  });

  test('vaat kaydıracı şema türünün üst sınırını aşamaz', () {
    final t = _type('profitShareHolding');
    final s = _fresh(cfg, t);
    final r = tick(s, [SetPromisedRate(0.5)], SimRng(1), cfg, events, t);
    expect(r.state.promisedRateWeekly, t.maxRateWeekly);
  });

  test('satış koşulu tutmuyorsa hamle şemayı bitirmez', () {
    final t = _type('classicPonzi');
    // 1. hafta: alıcı defter görmek ister, henüz defter yok.
    final r = tick(_fresh(cfg, t), const [SellScheme()], SimRng(1), cfg, events, t);
    expect(r.state.isOver, isFalse);
    expect(r.log.any((l) => l.contains('masadan kalktı')), isTrue);
  });

  test('satış şemayı bitirir ve temiz para yazar', () {
    final t = _type('productionCover');
    var s = _run(_fresh(cfg, t), 20, SimRng(2), cfg, events, t);
    expect(canSell(s, t), isTrue, reason: '20. haftada satılabilir olmalı');
    s = tick(s, const [SellScheme()], SimRng(2), cfg, events, t).state;
    expect(s.end, SchemeEnd.sold);

    final career = closeChapter(
        career: const CareerState.fresh(), scheme: s, type: t);
    expect(career.cleanMoney, greaterThan(0));
    expect(career.over, isFalse);
    expect(career.chapters.single.end, SchemeEnd.sold);
  });

  test('devir kasayı bırakır, yalnız cebi taşır', () {
    final t = _type('classicPonzi');
    var s = _run(_fresh(cfg, t), 20, SimRng(3), cfg, events, t);
    final pocket = s.totalSkimmed;
    s = tick(s, const [HandOverScheme()], SimRng(3), cfg, events, t).state;
    expect(s.end, SchemeEnd.handedOver);

    final career = closeChapter(
        career: const CareerState.fresh(), scheme: s, type: t);
    expect(career.dirtyMoney, closeTo(pocket, 0.001));
    expect(career.cleanMoney, 0);
  });

  test('kaçış kasayı ve cebi kara para olarak taşır', () {
    final t = _type('classicPonzi');
    var s = _run(_fresh(cfg, t), 20, SimRng(5), cfg, events, t);
    final gross = s.cash + s.totalSkimmed;
    s = tick(s, const [Flee()], SimRng(5), cfg, events, t).state;

    final career = closeChapter(
        career: const CareerState.fresh(), scheme: s, type: t);
    // Hazırlıksız kaçışta paranın çoğu yolda kalır: nakit taşımak, acele
    // bilet, aracıya kaptırılan pay.
    expect(career.dirtyMoney, lessThan(gross));
    expect(career.dirtyMoney, greaterThan(0));
    expect(career.record, greaterThan(0));
    expect(career.over, isFalse);
  });

  test('hazırlıklı kaçış daha çok para ve daha az iz bırakır', () {
    final t = _type('classicPonzi');
    var s = _run(_fresh(cfg, t), 20, SimRng(5), cfg, events, t);
    s = tick(s, const [Flee()], SimRng(5), cfg, events, t).state;

    final rushed = closeChapter(
        career: const CareerState.fresh(), scheme: s, type: t);
    final planned = closeChapter(
        career: const CareerState.fresh(),
        scheme: s,
        type: t,
        escapeReadiness: 1.0);

    expect(planned.dirtyMoney, greaterThan(rushed.dirtyMoney));
    expect(planned.record, lessThan(rushed.record));
  });

  test('kaçış planı kullanılınca tükenir, satışta durur', () {
    final t = _type('productionCover');
    var s = _run(_fresh(cfg, t), 20, SimRng(2), cfg, events, t);
    const start = CareerState.fresh();
    final withPlan = start.copyWith(escapeParts: ['passport', 'offshore']);

    final fledState = tick(s, const [Flee()], SimRng(2), cfg, events, t).state;
    final afterFlee =
        closeChapter(career: withPlan, scheme: fledState, type: t);
    expect(afterFlee.escapeParts, isEmpty);

    final soldState =
        tick(s, const [SellScheme()], SimRng(2), cfg, events, t).state;
    final afterSale =
        closeChapter(career: withPlan, scheme: soldState, type: t);
    expect(afterSale.escapeParts, hasLength(2));
  });

  test('baskın ve toplu çekim kariyeri bitirir', () {
    final t = _type('classicPonzi');
    final s = _run(_fresh(cfg, t, rate: t.maxRateWeekly), 1200, SimRng(6), cfg,
        events, t);
    expect(s.end!.endsCareer, isTrue);
    final career = closeChapter(
        career: const CareerState.fresh(), scheme: s, type: t);
    expect(career.over, isTrue);
    expect(career.overReason, isNotNull);
    expect(career.record, 100);
  });

  test('geçmiş dosyası yeni şemayı daha şüpheli başlatır', () {
    final t = _type('classicPonzi');
    final s = SchemeState.initial(
      type: t,
      cash: t.startCash,
      seedInvestors: 10,
      seedTicket: cfg.segments[t.seedSegment]!.ticket,
      startingSuspicion: 40,
    );
    expect(s.suspicion, 40);
  });

  test('kara para sermayeye girerken erir', () {
    const career = CareerState(
      cleanMoney: 100,
      dirtyMoney: 100,
      record: 0,
      playedSchemeIds: [],
      chapters: [],
      businesses: [],
      contacts: [],
      escapeParts: [],
      partner: null,
      over: false,
      overReason: null,
    );
    expect(career.usableCapital, lessThan(200));
    expect(career.usableCapital, greaterThan(100));
  });
}
