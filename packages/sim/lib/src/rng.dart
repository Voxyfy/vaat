import 'dart:math';

/// Seed'li rastgele sayı üreteci.
///
/// Neden sarmalıyoruz: simülasyonun tek rastgelelik kaynağı bu sınıf olsun ki
/// aynı seed ile aynı run yeniden üretilebilsin. `dart:math`'in Random'ı aynı
/// Dart sürümünde deterministiktir; sürüm atlarken kayıt dosyaları eski
/// sonuçları yeniden üretmeyebilir, bu kabul edilmiş bir risk.
class SimRng {
  SimRng(this.seed) : _random = Random(seed);

  final int seed;
  final Random _random;

  double nextDouble() => _random.nextDouble();

  int nextInt(int max) => _random.nextInt(max);

  /// Beklenen değeri kesirli olan bir sayımı tam sayıya çevirir.
  /// 2,3 bekleniyorsa %70 ihtimalle 2, %30 ihtimalle 3 döner. Neden: yatırımcı
  /// sayısı gibi küçük sayımlarda sürekli aşağı yuvarlamak büyümeyi öldürür.
  int stochasticRound(double expected) {
    final base = expected.floor();
    final fraction = expected - base;
    return base + (nextDouble() < fraction ? 1 : 0);
  }
}
