import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:vaat_sim/vaat_sim.dart';

BalanceConfig _cfg() => BalanceConfig.fromJsonString(
    File('../../content/balance.json').readAsStringSync());
List<SchemeType> _schemes() => SchemeType.listFromJsonString(
    File('../../content/schemes.json').readAsStringSync());

/// Kayıt formatının doğruluğu. Eksik bir alan sessizce varsayılana düşerse
/// oyuncu kaydını bozulmuş sanmaz, sadece oyun tuhaf davranır; bu yüzden
/// her şey gidiş dönüş test ediliyor.
void main() {
  final cfg = _cfg();
  final schemes = _schemes();
  final events = EventEngine(const []);

  /// Bir şemayı biraz oynatır ki state boş olmasın.
  SchemeState played(SchemeType type, {int weeks = 25}) {
    var s = SchemeState.initial(
      type: type,
      cash: type.startCash,
      seedInvestors: 10,
      seedTicket: cfg.segments[type.seedSegment]!.ticket,
    );
    final rng = SimRng(4);
    for (var i = 0; i < weeks && !s.isOver; i++) {
      final actions = <PlayerAction>[
        if (i == 2) const Marketing(50000),
        if (i == 3) OpenSegment(type.segments.last),
        if (i == 5 && s.board.isActive) BuyStock(s.board.stocks.first.id, 100),
        if (i == 6 && s.board.isActive)
          ManipulateStock(s.board.stocks.first.id, Manipulation.spoof),
      ];
      s = tick(s, actions, rng, cfg, events, type).state;
    }
    return s;
  }

  test('şema durumu gidiş dönüş korunur', () {
    for (final type in schemes) {
      final before = played(type);
      final after =
          schemeFromJson(jsonDecode(jsonEncode(schemeToJson(before))) as Map<String, dynamic>);

      expect(after.typeId, before.typeId, reason: type.id);
      expect(after.week, before.week, reason: type.id);
      expect(after.cash, before.cash, reason: type.id);
      expect(after.promisedRateWeekly, before.promisedRateWeekly);
      expect(after.skim, before.skim);
      expect(after.fixedCostWeekly, before.fixedCostWeekly);
      expect(after.panic, before.panic);
      expect(after.missedPayments, before.missedPayments);
      expect(after.bankRun, before.bankRun);
      expect(after.suspicion, before.suspicion);
      expect(after.totalInflow, before.totalInflow);
      expect(after.totalPaidOut, before.totalPaidOut);
      expect(after.totalSkimmed, before.totalSkimmed);
      expect(after.promisedTotal, closeTo(before.promisedTotal, 1e-6));
      expect(after.investorCount, before.investorCount);
      expect(after.firedEventIds, before.firedEventIds);
      expect(after.pendingEventIds, before.pendingEventIds);
      expect(after.end, before.end);
      expect(after.endReason, before.endReason);

      // Piyasa
      expect(after.market.index, before.market.index);
      expect(after.market.regime, before.market.regime);
      expect(after.market.weeksInRegime, before.market.weeksInRegime);
      expect(after.market.lastChange, before.market.lastChange);

      // Segmentler
      expect(after.segments.keys.toSet(), before.segments.keys.toSet());
      for (final key in before.segments.keys) {
        expect(after.segments[key]!.investors, before.segments[key]!.investors);
        expect(after.segments[key]!.promised, before.segments[key]!.promised);
        expect(after.segments[key]!.open, before.segments[key]!.open);
      }

      // Süreli etkiler
      expect(after.modifiers.length, before.modifiers.length);
      for (var i = 0; i < before.modifiers.length; i++) {
        expect(after.modifiers[i].kind, before.modifiers[i].kind);
        expect(after.modifiers[i].multiplier, before.modifiers[i].multiplier);
        expect(after.modifiers[i].weeksLeft, before.modifiers[i].weeksLeft);
      }

      // Borsa
      expect(after.board.stocks.length, before.board.stocks.length);
      for (var i = 0; i < before.board.stocks.length; i++) {
        final a = after.board.stocks[i];
        final b = before.board.stocks[i];
        expect(a.id, b.id);
        expect(a.price, b.price);
        expect(a.shares, b.shares);
        expect(a.avgCost, b.avgCost);
        expect(a.heat, b.heat);
        expect(a.floatSize, b.floatSize);
        expect(a.history, b.history);
      }
      expect(after.board.pending.length, before.board.pending.length);
    }
  });

  test('kaydedilen durumdan devam eden koşu ile kesintisiz koşu aynı', () {
    final type = schemes.first;
    final rng1 = SimRng(12);
    var straight = SchemeState.initial(
      type: type,
      cash: type.startCash,
      seedInvestors: 10,
      seedTicket: cfg.segments[type.seedSegment]!.ticket,
    );
    for (var i = 0; i < 30; i++) {
      straight = tick(straight, const [], rng1, cfg, events, type).state;
    }

    // Aynı koşuyu 15. haftada kaydedip yükleyerek sürdür.
    final rng2 = SimRng(12);
    var s = SchemeState.initial(
      type: type,
      cash: type.startCash,
      seedInvestors: 10,
      seedTicket: cfg.segments[type.seedSegment]!.ticket,
    );
    for (var i = 0; i < 15; i++) {
      s = tick(s, const [], rng2, cfg, events, type).state;
    }
    s = schemeFromJson(
        jsonDecode(jsonEncode(schemeToJson(s))) as Map<String, dynamic>);
    for (var i = 0; i < 15; i++) {
      s = tick(s, const [], rng2, cfg, events, type).state;
    }

    expect(s.week, straight.week);
    expect(s.cash, closeTo(straight.cash, 1e-6));
    expect(s.suspicion, closeTo(straight.suspicion, 1e-6));
    expect(s.investorCount, straight.investorCount);
  });

  test('kariyer gidiş dönüş korunur', () {
    final type = schemes.first;
    var scheme = played(type, weeks: 20);
    scheme = tick(scheme, const [Flee()], SimRng(1), cfg, events, type).state;
    final career = closeChapter(
      career: const CareerState.fresh()
          .copyWith(businesses: ['exchange'], contacts: ['lawyer', 'fixer']),
      scheme: scheme,
      type: type,
      escapeReadiness: 0.5,
    ).copyWith(partner: PartnerKind.political, escapeParts: ['passport']);

    final after = careerFromJson(
        jsonDecode(jsonEncode(careerToJson(career))) as Map<String, dynamic>);

    expect(after.cleanMoney, career.cleanMoney);
    expect(after.dirtyMoney, career.dirtyMoney);
    expect(after.record, career.record);
    expect(after.playedSchemeIds, career.playedSchemeIds);
    expect(after.businesses, career.businesses);
    expect(after.contacts, career.contacts);
    expect(after.escapeParts, career.escapeParts);
    expect(after.partner, career.partner);
    expect(after.over, career.over);
    expect(after.overReason, career.overReason);
    expect(after.chapters.length, career.chapters.length);
    for (var i = 0; i < career.chapters.length; i++) {
      final a = after.chapters[i];
      final b = career.chapters[i];
      expect(a.schemeId, b.schemeId);
      expect(a.schemeName, b.schemeName);
      expect(a.weeks, b.weeks);
      expect(a.end, b.end);
      expect(a.collected, b.collected);
      expect(a.victims, b.victims);
      expect(a.tookHome, b.tookHome);
    }
  });

  test('bitmiş kariyer de kaydedilebilir', () {
    final type = schemes.first;
    var s = SchemeState.initial(
      type: type,
      cash: type.startCash,
      seedInvestors: 10,
      seedTicket: cfg.segments[type.seedSegment]!.ticket,
      promisedRateWeekly: type.maxRateWeekly,
    );
    final rng = SimRng(8);
    for (var i = 0; i < 400 && !s.isOver; i++) {
      s = tick(s, const [], rng, cfg, events, type).state;
    }
    expect(s.isOver, isTrue);
    final career =
        closeChapter(career: const CareerState.fresh(), scheme: s, type: type);
    expect(career.over, isTrue);

    final after = careerFromJson(
        jsonDecode(jsonEncode(careerToJson(career))) as Map<String, dynamic>);
    expect(after.over, isTrue);
    expect(after.overReason, career.overReason);
  });
}
