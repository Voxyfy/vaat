import 'dart:io';

import 'package:test/test.dart';
import 'package:vaat_sim/vaat_sim.dart';

BalanceConfig _cfg() => BalanceConfig.fromJsonString(
      File('../../content/balance.json').readAsStringSync(),
    );

SchemeType _stockType() => SchemeType.listFromJsonString(
      File('../../content/schemes.json').readAsStringSync(),
    ).firstWhere((t) => t.id == 'stockManipulation');

SchemeState _fresh(BalanceConfig cfg, SchemeType t) => SchemeState.initial(
      type: t,
      cash: t.startCash,
      seedInvestors: 4,
      seedTicket: cfg.segments[t.seedSegment]!.ticket,
    );

void main() {
  final cfg = _cfg();
  final type = _stockType();
  final events = EventEngine(const []);

  test('borsa şeması hisse tahtasıyla açılır, diğerleri açılmaz', () {
    final board = _fresh(cfg, type).board;
    expect(board.isActive, isTrue);
    expect(board.stocks, hasLength(6));

    final ponzi = SchemeType.listFromJsonString(
            File('../../content/schemes.json').readAsStringSync())
        .firstWhere((t) => t.id == 'classicPonzi');
    final plain = SchemeState.initial(
      type: ponzi,
      cash: ponzi.startCash,
      seedInvestors: 10,
      seedTicket: cfg.segments[ponzi.seedSegment]!.ticket,
    );
    expect(plain.board.isActive, isFalse);
  });

  test('alım kasadan düşer, satış kasaya yazar', () {
    var s = _fresh(cfg, type);
    final id = s.board.stocks.first.id;
    final price = s.board.byId(id)!.price;
    final cashBefore = s.cash;

    s = tick(s, [BuyStock(id, 100)], SimRng(1), cfg, events, type).state;
    expect(s.board.byId(id)!.shares, 100);
    expect(s.cash, lessThan(cashBefore));
    expect(s.board.byId(id)!.avgCost, closeTo(price, 0.001));

    // Satışın etkisini izole etmek için aynı haftayı hamlesiz koşan bir
    // kopyayla karşılaştırıyoruz: tick zaten sabit gider ve çekim düşüyor.
    final control = tick(s, const [], SimRng(1), cfg, events, type).state;
    s = tick(s, [SellStock(id, 100)], SimRng(1), cfg, events, type).state;
    expect(s.board.byId(id)!.shares, 0);
    expect(s.cash, greaterThan(control.cash));
  });

  test('parası yetmeyen alım sessiz kalmaz', () {
    var s = _fresh(cfg, type).copyWith(cash: 10);
    final id = s.board.stocks.first.id;
    final r = tick(s, [BuyStock(id, 100000)], SimRng(1), cfg, events, type);
    expect(r.state.board.byId(id)!.shares, 0);
    expect(r.log.any((l) => l.contains('yeterli para yok')), isTrue);
  });

  test('manipülasyon fiyatı iter, iz bırakır, sonra geri çeker', () {
    var s = _fresh(cfg, type);
    final id = s.board.stocks.first.id;
    final before = s.board.byId(id)!.price;

    s = tick(s, [ManipulateStock(id, Manipulation.pumpAndDump)], SimRng(2),
            cfg, events, type)
        .state;
    final peak = s.board.byId(id)!.price;
    expect(peak, greaterThan(before * 1.2), reason: 'pump fiyatı sıçratmalı');
    expect(s.board.byId(id)!.heat, greaterThan(20));

    // Etki sönerken fiyat geri çekilir: geç satan zarar eder.
    for (var i = 0; i < 4; i++) {
      s = tick(s, const [], SimRng(2), cfg, events, type).state;
    }
    expect(s.board.byId(id)!.price, lessThan(peak));
  });

  test('manipülasyon izi şüpheyi besler', () {
    var clean = _fresh(cfg, type);
    var dirty = _fresh(cfg, type);
    final id = dirty.board.stocks.first.id;
    dirty = tick(dirty, [ManipulateStock(id, Manipulation.pumpAndDump)],
            SimRng(5), cfg, events, type)
        .state;
    for (var i = 0; i < 6; i++) {
      clean = tick(clean, const [], SimRng(5), cfg, events, type).state;
      dirty = tick(dirty, const [], SimRng(5), cfg, events, type).state;
    }
    expect(dirty.suspicion, greaterThan(clean.suspicion));
  });

  test('iz zamanla söner', () {
    var s = _fresh(cfg, type);
    final id = s.board.stocks.first.id;
    s = tick(s, [ManipulateStock(id, Manipulation.washTrade)], SimRng(7), cfg,
            events, type)
        .state;
    final hot = s.board.byId(id)!.heat;
    for (var i = 0; i < 10; i++) {
      s = tick(s, const [], SimRng(7), cfg, events, type).state;
    }
    expect(s.board.byId(id)!.heat, lessThan(hot));
  });

  test('fiyat geçmişi sınırlı büyür', () {
    var s = _fresh(cfg, type);
    for (var i = 0; i < 150 && !s.isOver; i++) {
      s = tick(s, const [], SimRng(9), cfg, events, type).state;
    }
    for (final stock in s.board.stocks) {
      expect(stock.history.length, lessThanOrEqualTo(104));
    }
  });
}
