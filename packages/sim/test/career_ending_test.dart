import 'dart:convert';

import 'package:test/test.dart';
import 'package:vaat_sim/vaat_sim.dart';

/// Kariyer sonları. Oyuncu kazanmaz, yalnız daha iyi çekilir; hangi sonun ne
/// zaman açıldığı ve skora ne yaptığı burada sabit.
void main() {
  ChapterRecord chapter(String id, SchemeEnd end, {int weeks = 40}) =>
      ChapterRecord(
        schemeId: id,
        schemeName: id,
        weeks: weeks,
        end: end,
        collected: 1e6,
        victims: 100,
        tookHome: 1e5,
      );

  CareerState career({
    double clean = 1e6,
    double dirty = 0,
    double record = 0,
    List<String> parts = const [],
    List<ChapterRecord> chapters = const [],
  }) =>
      CareerState(
        cleanMoney: clean,
        dirtyMoney: dirty,
        record: record,
        playedSchemeIds: const [],
        chapters: chapters.isEmpty
            ? [chapter('classicPonzi', SchemeEnd.fled)]
            : chapters,
        businesses: const [],
        contacts: const [],
        escapeParts: parts,
        partner: null,
        over: false,
        overReason: null,
      );

  test('çiftlik ülke ve yurt dışı hesap ister, pasaport Balkan açar', () {
    expect(career().availableEndings(), isEmpty);
    expect(career(parts: ['country']).canEnd(CareerEnding.farm), isFalse);
    expect(
      career(parts: ['country', 'offshore']).canEnd(CareerEnding.farm),
      isTrue,
    );
    expect(career(parts: ['passport']).availableEndings(),
        [CareerEnding.balkan]);
  });

  test('kurumsal ölümsüzlük iki holding satışı ister', () {
    final one = career(chapters: [
      chapter('profitShareHolding', SchemeEnd.sold),
      chapter('classicPonzi', SchemeEnd.sold),
    ]);
    expect(one.canEnd(CareerEnding.corporate), isFalse);
    final two = career(chapters: [
      chapter('profitShareHolding', SchemeEnd.sold),
      chapter('profitShareHolding', SchemeEnd.sold),
    ]);
    expect(two.canEnd(CareerEnding.corporate), isTrue);
  });

  test('itiraf ve itirafçı dosya ağırken, sefalet para yokken açılır', () {
    expect(career(record: 40).canEnd(CareerEnding.confession), isFalse);
    expect(career(record: 55).canEnd(CareerEnding.confession), isTrue);
    expect(career(record: 55).canEnd(CareerEnding.informant), isFalse);
    expect(career(record: 60).canEnd(CareerEnding.informant), isTrue);
    expect(career(clean: 50000).canEnd(CareerEnding.poverty), isTrue);
    expect(career(clean: 500000).canEnd(CareerEnding.poverty), isFalse);
  });

  test('hapis seçilemez, yakalanma onu kendisi yazar', () {
    expect(career().canEnd(CareerEnding.prison), isFalse);
    expect(CareerEnding.prison.voluntary, isFalse);
  });

  test('çekilme kariyeri bitirir ve skor çarpanı işler', () {
    final c = career(parts: ['country', 'offshore']);
    final open = c.score;
    final farm = c.retire(CareerEnding.farm);
    expect(farm.over, isTrue);
    expect(farm.ending, CareerEnding.farm);
    expect(farm.score, closeTo(open, 1e-6));
    expect(farm.partner, isNull);

    final balkan =
        career(dirty: 1e6, parts: ['passport']).retire(CareerEnding.balkan);
    expect(balkan.dirtyMoney, closeTo(7e5, 1e-6));
    expect(balkan.score, lessThan(open));

    final informant = career(record: 70).retire(CareerEnding.informant);
    expect(informant.cleanMoney, closeTo(2e5, 1e-6));
    expect(informant.score, greaterThan(0));

    final confession = career(record: 70).retire(CareerEnding.confession);
    expect(confession.cleanMoney, 0);
    expect(confession.score, 0);
  });

  test('hapis skoru sıfırlar, ceza yılı mağdurla büyür', () {
    final caught = career().copyWith(
      over: true,
      ending: CareerEnding.prison,
    );
    expect(caught.score, 0);
    expect(caught.prisonYears, 500);
  });

  test('son kayıttan geri gelir, eski biten kayıt hapse düşer', () {
    final c = career(parts: ['passport']).retire(CareerEnding.balkan);
    final json = jsonDecode(jsonEncode(careerToJson(c))) as Map<String, dynamic>;
    expect(careerFromJson(json).ending, CareerEnding.balkan);

    json.remove('ending');
    expect(careerFromJson(json).ending, CareerEnding.prison);
    json['over'] = false;
    expect(careerFromJson(json).ending, isNull);
  });
}
