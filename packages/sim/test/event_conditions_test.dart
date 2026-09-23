import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:vaat_sim/vaat_sim.dart';

/// Kariyere ve geçmiş kararlara bağlı olay koşulları. Bu koşullar yanlış
/// çalışırsa kart ya hiç gelmez ya da herkese gelir; ikisini de oyunda
/// kimse fark etmez, bu yüzden burada sabitleniyor.
void main() {
  final cfg = BalanceConfig.fromJsonString(
      File('../../content/balance.json').readAsStringSync());
  final type = SchemeType.listFromJsonString(
          File('../../content/schemes.json').readAsStringSync())
      .firstWhere((t) => t.id == 'classicPonzi');

  SchemeState fresh() => SchemeState.initial(
        type: type,
        cash: type.startCash,
        seedInvestors: 10,
        seedTicket: cfg.segments[type.seedSegment]!.ticket,
      );

  // JSON'dan geçiriliyor: içerik dosyadan böyle geliyor, elle yazılan
  // map literal'lerinin tipi dosyadakiyle aynı değil.
  EventDef card(String id, Map<String, dynamic> conditions) =>
      EventDef.fromJson(jsonDecode(jsonEncode({
        'id': id,
        'title': id,
        'text': id,
        'conditions': conditions,
        'options': [
          {'label': 'a', 'effects': {'cash': -1}},
          {'label': 'b', 'effects': {}},
        ],
      })) as Map<String, dynamic>);

  test('owns: işletme veya tanıdıklardan biri yoksa kart gelmez', () {
    final c = card('club', {
      'owns': ['football', 'media'],
    }).conditions;
    final s = fresh();
    expect(c.matches(s), isFalse);
    expect(c.matches(s, const EventContext(owned: {'lawyer'})), isFalse);
    expect(c.matches(s, const EventContext(owned: {'media'})), isTrue);
  });

  test('partner: ortak şartı iki yönlü çalışır', () {
    final withP = card('p', {'partner': true}).conditions;
    final withoutP = card('np', {'partner': false}).conditions;
    final s = fresh();
    const has = EventContext(hasPartner: true);
    expect(withP.matches(s), isFalse);
    expect(withP.matches(s, has), isTrue);
    expect(withoutP.matches(s), isTrue);
    expect(withoutP.matches(s, has), isFalse);
  });

  test('after: öncül, seçenek ve bekleme süresi birlikte aranır', () {
    final c = card('follow', {
      'after': {
        'event': 'root',
        'options': [0],
        'minWeeks': 3,
      },
    }).conditions;
    var s = fresh().copyWith(week: 10);
    expect(c.matches(s), isFalse, reason: 'öncül hiç oynanmadı');

    s = s.copyWith(
        eventChoices: {'root': const EventChoice(option: 1, week: 5)});
    expect(c.matches(s), isFalse, reason: 'başka seçenek seçildi');

    s = s.copyWith(
        eventChoices: {'root': const EventChoice(option: 0, week: 8)});
    expect(c.matches(s), isFalse, reason: 'süre dolmadı');
    expect(c.matches(s.copyWith(week: 11)), isTrue);
  });

  test('cevap ve cevapsız kalan kart seçim olarak kaydedilir', () {
    final engine = EventEngine([card('root', {}), card('other', {})]);
    var s = fresh().copyWith(pendingEventIds: ['root', 'other'], week: 4);
    s = tick(s, const [ResolveEvent('root', 0)], SimRng(1), cfg, engine, type)
        .state;
    expect(s.eventChoices['root']?.option, 0);
    expect(s.eventChoices['root']?.week, 4);
    // Cevapsız kart son seçenekle kapanır; zincirler bunu da görmeli.
    expect(s.eventChoices['other']?.option, 1);
  });

  test('zincirli kart yalnız öncül oynanınca çekilir', () {
    final engine = EventEngine(
      [card('follow', {'after': {'event': 'root'}})],
      baseChancePerWeek: 0.9,
    );
    final base = fresh().copyWith(week: 12);
    for (var seed = 0; seed < 20; seed++) {
      expect(engine.draw(base, SimRng(seed)), isEmpty);
    }
    final played = base.copyWith(
        eventChoices: {'root': const EventChoice(option: 1, week: 2)});
    final hits = [
      for (var seed = 0; seed < 20; seed++) engine.draw(played, SimRng(seed)),
    ].where((d) => d.isNotEmpty);
    expect(hits, isNotEmpty);
  });

  test('seçimler kayıttan geri gelir, eski kayıt boş başlar', () {
    final s = fresh().copyWith(
        eventChoices: {'root': const EventChoice(option: 2, week: 7)});
    final json = jsonDecode(jsonEncode(schemeToJson(s))) as Map<String, dynamic>;
    final back = schemeFromJson(json);
    expect(back.eventChoices['root']?.option, 2);
    expect(back.eventChoices['root']?.week, 7);

    // Bu alan eklenmeden önce alınmış kayıt.
    json.remove('eventChoices');
    expect(schemeFromJson(json).eventChoices, isEmpty);
  });
}
