import 'dart:math' as math;

import 'rng.dart';

/// Piyasanın genel havası. Şemanın kendi sağlığından bağımsız, dışsal bir güç.
///
/// Neden var: gerçek Ponzi'leri çökerten şey genelde keşfedilmek değil,
/// likidite. 2008 krizi Madoff, Stanford, Petters ve Rothstein'ı aynı 12 ayda
/// düşürdü. Oyunda da çöküşün en sık sebebi oyuncunun hatası değil, kötü
/// zamanlama olmalı.
enum MarketRegime {
  /// Herkes yatırım hevesli. Para akar, kimse çekmez.
  bull,

  /// Sıradan hafta.
  normal,

  /// Tedirginlik. Akış yavaşlar, çekim artar.
  bear,

  /// Panik. Akış durur, herkes aynı anda nakit ister.
  crash,
}

/// Piyasanın haftalık durumu.
class MarketState {
  const MarketState({
    required this.index,
    required this.regime,
    required this.weeksInRegime,
    required this.lastChange,
  });

  const MarketState.initial()
      : index = 100,
        regime = MarketRegime.normal,
        weeksInRegime = 0,
        lastChange = 0;

  /// Endeks değeri. 100'den başlar, oyuncuya grafik olarak gösterilir.
  final double index;

  final MarketRegime regime;
  final int weeksInRegime;

  /// Son haftanın yüzde değişimi. Manşet ve renk için.
  final double lastChange;

  /// Yeni para akışına çarpan. Boğa piyasasında herkes yatırımcı olur.
  double get inflowMultiplier => switch (regime) {
        MarketRegime.bull => 1.5,
        MarketRegime.normal => 1.0,
        MarketRegime.bear => 0.7,
        MarketRegime.crash => 0.35,
      };

  /// Çekim talebine çarpan. Panikte herkes aynı anda kapıya yığılır.
  double get withdrawMultiplier => switch (regime) {
        MarketRegime.bull => 0.8,
        MarketRegime.normal => 1.0,
        MarketRegime.bear => 1.4,
        MarketRegime.crash => 2.6,
      };

  MarketState copyWith({
    double? index,
    MarketRegime? regime,
    int? weeksInRegime,
    double? lastChange,
  }) =>
      MarketState(
        index: index ?? this.index,
        regime: regime ?? this.regime,
        weeksInRegime: weeksInRegime ?? this.weeksInRegime,
        lastChange: lastChange ?? this.lastChange,
      );
}

/// Piyasayı bir hafta ilerletir.
///
/// Rejimler kendi aralarında geçiş yapar. Kriz kısa ve sert, boğa uzun ve
/// yumuşak: oyuncu iyi günlerde büyümeye, kötü günlerde hayatta kalmaya
/// çalışsın.
MarketState stepMarket(MarketState m, SimRng rng) {
  final regime = _nextRegime(m, rng);
  final drift = switch (regime) {
        MarketRegime.bull => 0.010,
        MarketRegime.normal => 0.002,
        MarketRegime.bear => -0.008,
        MarketRegime.crash => -0.055,
      } +
      // Gürültü: aynı rejim içinde de haftalar birbirine benzemesin.
      (rng.nextDouble() - 0.5) * 0.03;

  final index = math.max(5.0, m.index * (1 + drift));
  return MarketState(
    index: index,
    regime: regime,
    weeksInRegime: regime == m.regime ? m.weeksInRegime + 1 : 0,
    lastChange: m.index <= 0 ? 0 : (index - m.index) / m.index,
  );
}

/// Rejim geçişleri. Krizden çıkış hızlı, boğaya giriş yavaş.
MarketRegime _nextRegime(MarketState m, SimRng rng) {
  final roll = rng.nextDouble();
  return switch (m.regime) {
    // Boğa uzun sürer ama bir gün biter.
    MarketRegime.bull => roll < 0.06
        ? MarketRegime.normal
        : roll < 0.08
            ? MarketRegime.bear
            : MarketRegime.bull,
    MarketRegime.normal => roll < 0.05
        ? MarketRegime.bull
        : roll < 0.10
            ? MarketRegime.bear
            : MarketRegime.normal,
    // Ayı piyasası krize dönebilir; asıl tehlike burada.
    MarketRegime.bear => roll < 0.10
        ? MarketRegime.crash
        : roll < 0.25
            ? MarketRegime.normal
            : MarketRegime.bear,
    // Kriz kısa: birkaç hafta sonra toz duman dağılır, hasar kalır.
    MarketRegime.crash =>
      roll < 0.35 ? MarketRegime.bear : MarketRegime.crash,
  };
}
