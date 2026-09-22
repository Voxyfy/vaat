import 'dart:io';

import 'package:test/test.dart';
import 'package:vaat_sim/vaat_sim.dart';

BalanceConfig _cfg() => BalanceConfig.fromJsonString(
      File('../../content/balance.json').readAsStringSync(),
    );

List<SchemeType> _schemes() => SchemeType.listFromJsonString(
      File('../../content/schemes.json').readAsStringSync(),
    );

void main() {
  test('piyasa rejimleri zamanla değişir ve hepsi görülür', () {
    final rng = SimRng(11);
    var m = const MarketState.initial();
    final seen = <MarketRegime>{};
    for (var i = 0; i < 4000; i++) {
      m = stepMarket(m, rng);
      seen.add(m.regime);
      expect(m.index, greaterThan(0), reason: 'endeks sıfırın altına inmemeli');
    }
    expect(seen, containsAll(MarketRegime.values),
        reason: 'uzun koşuda dört rejim de çıkmalı');
  });

  test('kriz akışı kısar, çekimi artırır', () {
    const crash = MarketState(
        index: 60, regime: MarketRegime.crash, weeksInRegime: 2, lastChange: -0.05);
    const bull = MarketState(
        index: 140, regime: MarketRegime.bull, weeksInRegime: 9, lastChange: 0.01);
    expect(crash.inflowMultiplier, lessThan(bull.inflowMultiplier));
    expect(crash.withdrawMultiplier, greaterThan(bull.withdrawMultiplier));
  });

  test('piyasa duyarlılığı şema türüne göre ayrışır', () {
    final schemes = _schemes();
    final crypto = schemes.firstWhere((t) => t.id == 'cryptoExchange');
    final holding = schemes.firstWhere((t) => t.id == 'profitShareHolding');
    // Kripto borsası piyasayla birlikte uçar ve düşer; cemaat parası aldırmaz.
    expect(crypto.marketSensitivity, greaterThan(holding.marketSensitivity));
  });

  test('tick piyasayı ilerletir ve state e yazar', () {
    final cfg = _cfg();
    final type = _schemes().first;
    final events = EventEngine(const []);
    final rng = SimRng(3);
    var s = SchemeState.initial(
      type: type,
      cash: type.startCash,
      seedInvestors: 10,
      seedTicket: cfg.segments[type.seedSegment]!.ticket,
    );
    expect(s.market.index, 100);

    final indices = <double>[];
    for (var i = 0; i < 50 && !s.isOver; i++) {
      s = tick(s, const [], rng, cfg, events, type).state;
      indices.add(s.market.index);
    }
    expect(indices.toSet().length, greaterThan(1),
        reason: 'endeks hafta hafta değişmeli');
  });

  test('aynı seed aynı piyasa yolunu üretir', () {
    List<double> run() {
      final rng = SimRng(77);
      var m = const MarketState.initial();
      return [for (var i = 0; i < 40; i++) (m = stepMarket(m, rng)).index];
    }

    expect(run(), run());
  });
}
