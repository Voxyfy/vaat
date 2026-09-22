import 'dart:io';

import 'package:test/test.dart';
import 'package:vaat_sim/vaat_sim.dart';

/// Oynanışta yakalanan hataların tekrar etmemesi için.
void main() {
  final cfg = BalanceConfig.fromJsonString(
      File('../../content/balance.json').readAsStringSync());
  final schemes = SchemeType.listFromJsonString(
      File('../../content/schemes.json').readAsStringSync());
  final events = EventEngine(const []);

  test('vaat kaydıracı türün tavanının üstüne çıkamaz', () {
    // Oyuncu raporu: kaydıracı yukarı çekince değer bir sonraki hafta geri
    // düşüyordu. Sebep arayüzdeki sabit tavandı; simülasyon türün tavanına
    // kırpıyor. Kırpma doğru davranış, burada onu sabitliyoruz.
    for (final type in schemes) {
      final s = SchemeState.initial(
        type: type,
        cash: type.startCash,
        seedInvestors: 5,
        seedTicket: cfg.segments[type.seedSegment]!.ticket,
      );
      final r = tick(s, const [SetPromisedRate(0.99)], SimRng(1), cfg, events,
          type);
      expect(r.state.promisedRateWeekly, type.maxRateWeekly,
          reason: '${type.id} tavanı aşmamalı');
    }
  });

  test('tavanın altındaki bir vaat aynen korunur', () {
    for (final type in schemes) {
      final target = type.maxRateWeekly * 0.5;
      var s = SchemeState.initial(
        type: type,
        cash: type.startCash,
        seedInvestors: 5,
        seedTicket: cfg.segments[type.seedSegment]!.ticket,
      );
      s = tick(s, [SetPromisedRate(target)], SimRng(1), cfg, events, type).state;
      expect(s.promisedRateWeekly, closeTo(target, 1e-9), reason: type.id);
      // Sonraki hafta hamlesiz geçince de değişmemeli.
      s = tick(s, const [], SimRng(1), cfg, events, type).state;
      expect(s.promisedRateWeekly, closeTo(target, 1e-9), reason: type.id);
    }
  });
}
