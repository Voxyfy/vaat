import 'package:test/test.dart';
import 'package:vaat_sim/vaat_sim.dart';

void main() {
  group('Basit aylık model', () {
    test('yeni para vaatten hızlı büyürse çökmez (Artzrouni B1)', () {
      // ri = %10 > rp - rw = %3: matematiksel olarak ölümsüz Ponzi.
      expect(
        monthsToCollapse(
          promisedMonthly: 0.05,
          withdrawMonthly: 0.02,
          inflowGrowthMonthly: 0.10,
        ),
        isNull,
      );
    });

    test('aynı set plato yapınca çöker', () {
      final months = monthsToCollapse(
        promisedMonthly: 0.05,
        withdrawMonthly: 0.02,
        inflowGrowthMonthly: 0.10,
        plateauMonth: 24,
      );
      expect(months, isNotNull);
      expect(months!, greaterThan(24));
    });

    test('vaat yükselince ömür kısalır', () {
      final low = monthsToCollapse(
        promisedMonthly: 0.01,
        withdrawMonthly: 0.01,
        inflowGrowthMonthly: 0,
      )!;
      final high = monthsToCollapse(
        promisedMonthly: 0.05,
        withdrawMonthly: 0.01,
        inflowGrowthMonthly: 0,
      )!;
      expect(high, lessThan(low));
    });
  });
}
