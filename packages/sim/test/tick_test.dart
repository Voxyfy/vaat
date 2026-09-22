import 'dart:io';

import 'package:test/test.dart';
import 'package:vaat_sim/vaat_sim.dart';

BalanceConfig _loadCfg() => BalanceConfig.fromJsonString(
      File('../../content/balance.json').readAsStringSync(),
    );

EventEngine _loadEvents() => EventEngine(
      EventDef.listFromJsonString(
        File('../../content/events/core.json').readAsStringSync(),
      ),
    );

List<SchemeType> _loadSchemes() => SchemeType.listFromJsonString(
      File('../../content/schemes.json').readAsStringSync(),
    );

SchemeType _classic() =>
    _loadSchemes().firstWhere((t) => t.id == 'classicPonzi');

SchemeState _fresh(BalanceConfig cfg, {double rate = 0.012, SchemeType? type}) {
  final t = type ?? _classic();
  return SchemeState.initial(
    type: t,
    cash: t.startCash,
    seedInvestors: 10,
    seedTicket: cfg.segments[t.seedSegment]!.ticket,
    promisedRateWeekly: rate,
  );
}

SchemeState _run(SchemeState s, int weeks, SimRng rng, BalanceConfig cfg,
    EventEngine ev,
    {SchemeType? type}) {
  var state = s;
  final t = type ?? _classic();
  for (var i = 0; i < weeks && !state.isOver; i++) {
    state = tick(state, const [], rng, cfg, ev, t).state;
  }
  return state;
}

void main() {
  final cfg = _loadCfg();
  final events = _loadEvents();

  test('aynı seed aynı sonucu verir', () {
    final a = _run(_fresh(cfg), 120, SimRng(7), cfg, events);
    final b = _run(_fresh(cfg), 120, SimRng(7), cfg, events);
    expect(a.cash, a.cash);
    expect(b.cash, a.cash);
    expect(b.week, a.week);
    expect(b.suspicion, a.suspicion);
    expect(b.investorCount, a.investorCount);
    expect(b.end, a.end);
  });

  test('farklı seed farklı yol izler', () {
    final a = _run(_fresh(cfg), 120, SimRng(1), cfg, events);
    final b = _run(_fresh(cfg), 120, SimRng(2), cfg, events);
    expect(a.cash == b.cash && a.investorCount == b.investorCount, isFalse);
  });

  test('ekstre toplamı kasadan hızlı büyür, delik açılır', () {
    final s = _run(_fresh(cfg), 40, SimRng(3), cfg, events);
    expect(s.promisedTotal, greaterThan(s.cash));
    expect(s.coverage, lessThan(1.0));
  });

  test('aşırı vaat şemayı makul vaatten önce bitirir', () {
    final modest = _run(_fresh(cfg, rate: 0.008), 400, SimRng(5), cfg, events);
    final greedy = _run(_fresh(cfg, rate: 0.08), 400, SimRng(5), cfg, events);
    expect(greedy.isOver, isTrue);
    expect(greedy.week, lessThan(modest.isOver ? modest.week : 400));
  });

  test('kaçış şemayı bitirir ve cep korunur', () {
    var s = _run(_fresh(cfg), 30, SimRng(9), cfg, events);
    final pocket = s.totalSkimmed;
    s = tick(s, const [Flee()], SimRng(9), cfg, events, _classic()).state;
    expect(s.end, SchemeEnd.fled);
    expect(s.totalSkimmed, pocket);
  });

  test('bitmiş şemaya tick dokunmaz', () {
    var s = _run(_fresh(cfg), 10, SimRng(9), cfg, events);
    s = tick(s, const [Flee()], SimRng(9), cfg, events, _classic()).state;
    final again = tick(s, const [], SimRng(9), cfg, events, _classic()).state;
    expect(again.week, s.week);
    expect(again.cash, s.cash);
  });

  test('cevapsız olay son seçenekle kapanır', () {
    // Şüpheyi zorla yükseltip gazeteci kartını tetikleyecek koşulu hazırla.
    var s = _fresh(cfg).copyWith(week: 10, suspicion: 50);
    var fired = false;
    for (var i = 0; i < 60 && !fired && !s.isOver; i++) {
      final r = tick(s, const [], SimRng(i), cfg, events, _classic());
      s = r.state;
      fired = r.newEvents.any((e) => e.id == 'journalist_math');
    }
    expect(fired, isTrue, reason: 'gazeteci kartı 60 haftada gelmeli');
    final before = s.suspicion;
    final r = tick(s, const [], SimRng(99), cfg, events, _classic());
    // Son seçenek "görmezden gel": şüphe +12, panik +0,25.
    expect(r.log.any((l) => l.contains('cevapsız kaldı')), isTrue);
    expect(r.state.pendingEventIds, isNot(contains('journalist_math')));
    expect(r.state.suspicion, greaterThan(before));
  });

  test('segment açma gider yazar ve kanalı açar', () {
    final s = _fresh(cfg);
    final r = tick(s, const [OpenSegment('tradesman')], SimRng(1), cfg, events, _classic());
    expect(r.state.segments['tradesman']!.open, isTrue);
    expect(r.state.cash, lessThan(s.cash + r.inflow));
  });
}
