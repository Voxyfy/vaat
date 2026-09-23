import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:vaat_sim/vaat_sim.dart';

/// İçerik dosyalarının bütünlüğü. 200 olay hedefine giderken bozuk bir kart
/// oyunu çalışırken patlatmasın: hatalar burada, derlemede çıksın.
void main() {
  final eventFiles = Directory('../../content/events')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList();

  final schemes = SchemeType.listFromJsonString(
      File('../../content/schemes.json').readAsStringSync());
  final balance = BalanceConfig.fromJsonString(
      File('../../content/balance.json').readAsStringSync());

  final events = [
    for (final f in eventFiles)
      ...EventDef.listFromJsonString(f.readAsStringSync()),
  ];

  test('olay dosyaları ayrıştırılabiliyor', () {
    expect(eventFiles, isNotEmpty);
    expect(events.length, greaterThanOrEqualTo(60));
  });

  test('olay id leri benzersiz', () {
    final ids = events.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('her olayın metni ve en az iki seçeneği var', () {
    for (final e in events) {
      expect(e.title.trim(), isNotEmpty, reason: e.id);
      expect(e.text.trim(), isNotEmpty, reason: e.id);
      expect(e.options.length, greaterThanOrEqualTo(2), reason: e.id);
      for (final o in e.options) {
        expect(o.label.trim(), isNotEmpty, reason: e.id);
      }
    }
  });

  test('olay koşullarındaki şema ve rejim adları gerçek', () {
    final schemeIds = schemes.map((t) => t.id).toSet();
    final regimeNames = MarketRegime.values.map((r) => r.name).toSet();
    for (final e in events) {
      for (final id in e.conditions.schemes) {
        expect(schemeIds, contains(id), reason: '${e.id} bilinmeyen şema: $id');
      }
      for (final r in e.conditions.regimes) {
        expect(regimeNames, contains(r), reason: '${e.id} bilinmeyen rejim: $r');
      }
    }
  });

  test('şema tanımlarındaki segmentler dengede tanımlı', () {
    for (final t in schemes) {
      expect(t.segments, contains(t.seedSegment), reason: t.id);
      for (final seg in t.segments) {
        expect(balance.segments.keys, contains(seg),
            reason: '${t.id} bilinmeyen segment: $seg');
      }
      expect(t.maxRateWeekly, greaterThanOrEqualTo(t.startRateWeekly),
          reason: t.id);
    }
  });

  test('her şema türü için en az bir özel olay var', () {
    for (final t in schemes) {
      final own = events.where((e) => e.conditions.schemes.contains(t.id));
      expect(own, isNotEmpty, reason: '${t.id} için özel olay yok');
    }
  });

  test('varlık dosyaları ayrıştırılabiliyor ve fiyatları pozitif', () {
    final biz = BusinessType.listFromJsonString(
        File('../../content/businesses.json').readAsStringSync());
    final contacts = ContactType.listFromJsonString(
        File('../../content/contacts.json').readAsStringSync());
    final parts = EscapePart.listFromJsonString(
        File('../../content/escape_plan.json').readAsStringSync());
    for (final item in [
      ...biz.map((b) => (b.id, b.name, b.price)),
      ...contacts.map((c) => (c.id, c.name, c.price)),
      ...parts.map((p) => (p.id, p.name, p.price)),
    ]) {
      expect(item.$2.trim(), isNotEmpty, reason: item.$1);
      expect(item.$3, greaterThan(0), reason: item.$1);
    }
    final allIds = [...biz.map((b) => b.id), ...contacts.map((c) => c.id)];
    expect(allIds.toSet().length, allIds.length);
  });

  test('sahiplik ve zincir koşulları gerçek şeylere bakıyor', () {
    final owned = {
      ...BusinessType.listFromJsonString(
              File('../../content/businesses.json').readAsStringSync())
          .map((b) => b.id),
      ...ContactType.listFromJsonString(
              File('../../content/contacts.json').readAsStringSync())
          .map((c) => c.id),
    };
    final byId = {for (final e in events) e.id: e};
    for (final e in events) {
      for (final id in e.conditions.owns) {
        expect(owned, contains(id), reason: '${e.id} bilinmeyen varlık: $id');
      }
      final link = e.conditions.after;
      if (link == null) continue;
      final parent = byId[link.event];
      expect(parent, isNotNull, reason: '${e.id} öncülü yok: ${link.event}');
      expect(link.event, isNot(e.id), reason: '${e.id} kendine bağlı');
      for (final i in link.options) {
        expect(i, inInclusiveRange(0, parent!.options.length - 1),
            reason: '${e.id} öncülde olmayan seçenek: $i');
      }
      // Öncül şemaya özelse zincir de o şemalarda kalmalı; yoksa kart
      // hiçbir zaman gelmez ve kimse fark etmez.
      if (parent!.conditions.schemes.isNotEmpty &&
          e.conditions.schemes.isNotEmpty) {
        expect(
          e.conditions.schemes.any(parent.conditions.schemes.contains),
          isTrue,
          reason: '${e.id} öncülüyle ortak şeması yok',
        );
      }
    }
  });

  test('etki alanları beklenen anahtarları kullanıyor', () {
    const known = {
      'cash', 'suspicion', 'panic', 'promisedRateDelta', 'skimDelta',
      'fixedCostDelta', 'channelMult', 'channelMultWeeks', 'withdrawMult',
      'withdrawMultWeeks',
    };
    for (final f in eventFiles) {
      for (final raw in jsonDecode(f.readAsStringSync()) as List) {
        final e = raw as Map<String, dynamic>;
        for (final o in e['options'] as List) {
          final effects =
              (o as Map<String, dynamic>)['effects'] as Map<String, dynamic>?;
          for (final key in effects?.keys ?? <String>[]) {
            expect(known, contains(key),
                reason: '${e['id']} bilinmeyen etki: $key');
          }
        }
      }
    }
  });
}
