import 'dart:io';

import 'package:test/test.dart';
import 'package:vaat_sim/vaat_sim.dart';

List<BusinessType> _biz() => BusinessType.listFromJsonString(
    File('../../content/businesses.json').readAsStringSync());
List<ContactType> _contacts() => ContactType.listFromJsonString(
    File('../../content/contacts.json').readAsStringSync());
List<EscapePart> _parts() => EscapePart.listFromJsonString(
    File('../../content/escape_plan.json').readAsStringSync());

void main() {
  final biz = _biz();
  final contacts = _contacts();
  final parts = _parts();
  final schemes = SchemeType.listFromJsonString(
      File('../../content/schemes.json').readAsStringSync());

  test('varlık dosyaları ayrıştırılabiliyor', () {
    expect(biz, isNotEmpty);
    expect(contacts, isNotEmpty);
    expect(parts, isNotEmpty);
  });

  test('kaçış planı parçalarının ağırlıkları bire tamamlanır', () {
    final total = parts.fold(0.0, (sum, p) => sum + p.weight);
    expect(total, closeTo(1.0, 1e-9));
  });

  test('işletmelerin açtığı şemalar gerçek', () {
    final ids = schemes.map((t) => t.id).toSet();
    for (final b in biz) {
      for (final u in b.unlocks) {
        expect(ids, contains(u), reason: '${b.id} bilinmeyen şema açıyor: $u');
      }
    }
  });

  test('aklama kapasitesi sahip olunan işletmelerle artar', () {
    const empty = CareerState.fresh();
    expect(empty.launderCapacity(biz), 0);

    final withExchange = empty.copyWith(businesses: ['exchange']);
    final withBoth = empty.copyWith(businesses: ['exchange', 'restaurants']);
    expect(withExchange.launderCapacity(biz), greaterThan(0));
    expect(withBoth.launderCapacity(biz),
        greaterThan(withExchange.launderCapacity(biz)));
  });

  test('kalkan koruma sağlar ama bağışıklık vermez', () {
    const empty = CareerState.fresh();
    expect(empty.suspicionShield(biz, contacts), 1.0);

    final protected = empty.copyWith(
      businesses: ['media', 'football', 'foundation'],
      contacts: ['lawyer', 'lobbyist', 'journalist'],
    );
    final shield = protected.suspicionShield(biz, contacts);
    expect(shield, lessThan(1.0));
    expect(shield, greaterThanOrEqualTo(0.35));
  });

  test('döviz bürosu dikkat çeker, kalkanı zayıflatır', () {
    const empty = CareerState.fresh();
    final withMedia = empty.copyWith(businesses: ['media']);
    final withExchange = empty.copyWith(businesses: ['exchange']);
    expect(withExchange.suspicionShield(biz, contacts),
        greaterThan(withMedia.suspicionShield(biz, contacts)));
  });

  test('kaçış hazırlığı parçalar ve tanıdıklarla artar, biri geçemez', () {
    const empty = CareerState.fresh();
    expect(empty.escapeReadiness(parts, contacts), 0);

    final full = empty.copyWith(
      escapeParts: parts.map((p) => p.id).toList(),
      contacts: ['fixer', 'banker', 'lawyer'],
    );
    expect(full.escapeReadiness(parts, contacts), 1.0);
  });

  test('ortak türleri farklı bedel ve fayda taşır', () {
    expect(PartnerKind.capital.capitalShare,
        greaterThan(PartnerKind.insider.capitalShare));
    expect(PartnerKind.political.suspicionFactor,
        lessThan(PartnerKind.celebrity.suspicionFactor));
    expect(PartnerKind.celebrity.channelFactor,
        greaterThan(PartnerKind.insider.channelFactor));
    // Ünlü ortak en çabuk konuşur, siyasi ortak en geç.
    expect(PartnerKind.celebrity.betrayalThreshold,
        lessThan(PartnerKind.political.betrayalThreshold));
  });

  test('kariyer kalkanı şüphe birikimini yavaşlatır', () {
    final cfg = BalanceConfig.fromJsonString(
        File('../../content/balance.json').readAsStringSync());
    final type = schemes.firstWhere((t) => t.id == 'classicPonzi');
    final events = EventEngine(const []);

    SchemeState run(CareerModifiers mods) {
      var s = SchemeState.initial(
        type: type,
        cash: type.startCash,
        seedInvestors: 10,
        seedTicket: cfg.segments[type.seedSegment]!.ticket,
        promisedRateWeekly: type.maxRateWeekly,
      );
      for (var i = 0; i < 25 && !s.isOver; i++) {
        s = tick(s, const [], SimRng(3), cfg, events, type, career: mods).state;
      }
      return s;
    }

    final bare = run(const CareerModifiers());
    final shielded = run(const CareerModifiers(suspicionShield: 0.5));
    expect(shielded.suspicion, lessThan(bare.suspicion));
  });
}
