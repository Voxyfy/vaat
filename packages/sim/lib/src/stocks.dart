import 'dart:math' as math;

import 'market.dart';
import 'rng.dart';

/// Tek bir hissenin durumu.
class Stock {
  const Stock({
    required this.id,
    required this.name,
    required this.price,
    required this.history,
    required this.shares,
    required this.avgCost,
    required this.heat,
    required this.floatSize,
  });

  final String id;
  final String name;
  final double price;

  /// Son haftaların fiyatı. Grafik için; uzunluğu sınırlı tutulur.
  final List<double> history;

  /// Oyuncunun elindeki lot.
  final int shares;

  /// Elindeki lotun ortalama maliyeti. Kâr zarar bundan hesaplanır.
  final double avgCost;

  /// Bu hissede biriken manipülasyon izi, 0 ile 100. Denetleyici bunu tarar.
  /// Zamanla söner, çünkü kimse eski işlemleri sonsuza dek incelemez.
  final double heat;

  /// Dolaşımdaki lot. Küçük hisseyi oynatmak kolay, büyüğü pahalı.
  final int floatSize;

  double get positionValue => shares * price;

  double get unrealized => shares * (price - avgCost);

  /// Fiyatı oynatmanın maliyeti dolaşımla ölçeklenir: küçük kâğıt ucuz.
  double get manipulationCost => floatSize * price * 0.02;

  Stock copyWith({
    double? price,
    List<double>? history,
    int? shares,
    double? avgCost,
    double? heat,
  }) =>
      Stock(
        id: id,
        name: name,
        price: price ?? this.price,
        history: history ?? this.history,
        shares: shares ?? this.shares,
        avgCost: avgCost ?? this.avgCost,
        heat: heat ?? this.heat,
        floatSize: floatSize,
      );
}

/// Manipülasyon türleri. Her biri gerçek bir teknik; etkileri ve bıraktığı iz
/// farklı. Sözlük ve tespit yöntemleri tasarım dokümanında.
enum Manipulation {
  /// Koordineli övgüyle fiyatı şişir. Büyük ve hızlı, iz de büyük.
  pumpAndDump,

  /// Kendi kendine alıp sat: sahte hacim, fiyat az oynar, dikkat çeker.
  washTrade,

  /// İptal niyetiyle emir koyup fiyatı it. Küçük ama ucuz etki.
  spoof,

  /// Kapanışa yakın küçük işlemlerle fiyatı çiz. Sessiz ve yavaş.
  paintTheTape,
}

extension ManipulationTraits on Manipulation {
  /// Fiyata uygulanan anlık çarpan.
  double get priceKick => switch (this) {
        Manipulation.pumpAndDump => 0.55,
        Manipulation.washTrade => 0.12,
        Manipulation.spoof => 0.20,
        Manipulation.paintTheTape => 0.08,
      };

  /// Hissede bıraktığı iz.
  double get heatCost => switch (this) {
        Manipulation.pumpAndDump => 34,
        Manipulation.washTrade => 20,
        Manipulation.spoof => 14,
        Manipulation.paintTheTape => 6,
      };

  /// Nakit maliyeti, hissenin manipülasyon maliyetiyle çarpılır.
  double get cashFactor => switch (this) {
        Manipulation.pumpAndDump => 1.0,
        Manipulation.washTrade => 0.5,
        Manipulation.spoof => 0.3,
        Manipulation.paintTheTape => 0.2,
      };

  /// Etkinin kaç hafta sürdüğü. Pump hızlı söner, tape uzun sürer.
  int get decayWeeks => switch (this) {
        Manipulation.pumpAndDump => 2,
        Manipulation.washTrade => 3,
        Manipulation.spoof => 1,
        Manipulation.paintTheTape => 6,
      };
}

/// Borsa katmanı. Yalnız hisse oynatılan şemalarda dolu olur.
class StockBoard {
  const StockBoard({required this.stocks, required this.pending});

  const StockBoard.empty() : stocks = const [], pending = const [];

  final List<Stock> stocks;

  /// Sönmeyi bekleyen manipülasyon etkileri.
  final List<PendingKick> pending;

  bool get isActive => stocks.isNotEmpty;

  double get portfolioValue =>
      stocks.fold(0.0, (sum, s) => sum + s.positionValue);

  double get unrealized => stocks.fold(0.0, (sum, s) => sum + s.unrealized);

  /// En yüksek iz. Denetleyici en sıcak kâğıda bakar.
  double get maxHeat =>
      stocks.isEmpty ? 0 : stocks.map((s) => s.heat).reduce(math.max);

  Stock? byId(String id) {
    for (final s in stocks) {
      if (s.id == id) return s;
    }
    return null;
  }

  StockBoard copyWith({List<Stock>? stocks, List<PendingKick>? pending}) =>
      StockBoard(
        stocks: stocks ?? this.stocks,
        pending: pending ?? this.pending,
      );

  /// Şema türünün hisse listesini kurar. Fiyatlar ve dolaşım sabit tohumdan
  /// türetilir ki her kariyer tanıdık bir tahtayla başlasın.
  factory StockBoard.create(List<(String, String, double, int)> defs) =>
      StockBoard(
        stocks: [
          for (final (id, name, price, float) in defs)
            Stock(
              id: id,
              name: name,
              price: price,
              history: [price],
              shares: 0,
              avgCost: 0,
              heat: 0,
              floatSize: float,
            ),
        ],
        pending: const [],
      );
}

/// Uygulanmış ama henüz sönmemiş bir manipülasyon etkisi.
class PendingKick {
  const PendingKick({
    required this.stockId,
    required this.remaining,
    required this.weeksLeft,
    this.fresh = true,
  });

  final String stockId;

  /// Kalan fiyat etkisi, oran olarak.
  final double remaining;

  final int weeksLeft;

  /// Bu hafta uygulanan manipülasyon. Sönme bir sonraki haftadan başlar;
  /// yoksa oyuncu şişirdiği fiyatı hiç göremeden geri iniyor.
  final bool fresh;
}

/// Borsayı bir hafta ilerletir.
///
/// Fiyatlar piyasa havasıyla birlikte yürür; manipülasyon etkisi kademeli
/// söner ve sönerken fiyatı geri çeker. "Pompala, tepede sat" oyunu buradan
/// çıkıyor: geç satarsan kendi şişirdiğin balonla birlikte iniyorsun.
StockBoard stepStocks(StockBoard board, MarketState market, SimRng rng) {
  if (!board.isActive) return board;

  final drift = switch (market.regime) {
    MarketRegime.bull => 0.012,
    MarketRegime.normal => 0.002,
    MarketRegime.bear => -0.010,
    MarketRegime.crash => -0.060,
  };

  final kicksByStock = <String, double>{};
  final nextPending = <PendingKick>[];
  for (final k in board.pending) {
    if (k.fresh) {
      // Bu hafta uygulandı: dokunma, sönme haftaya başlasın.
      nextPending.add(PendingKick(
        stockId: k.stockId,
        remaining: k.remaining,
        weeksLeft: k.weeksLeft,
        fresh: false,
      ));
      continue;
    }
    // Etkinin bu haftaki payı uygulanır, kalanı bir sonraki haftaya devreder.
    final share = k.remaining / k.weeksLeft;
    kicksByStock[k.stockId] = (kicksByStock[k.stockId] ?? 0) - share;
    if (k.weeksLeft > 1) {
      nextPending.add(PendingKick(
        stockId: k.stockId,
        remaining: k.remaining - share,
        weeksLeft: k.weeksLeft - 1,
        fresh: false,
      ));
    }
  }

  final stocks = [
    for (final s in board.stocks)
      () {
        final noise = (rng.nextDouble() - 0.5) * 0.09;
        final kick = kicksByStock[s.id] ?? 0;
        final price = math.max(0.5, s.price * (1 + drift + noise + kick));
        final history = [...s.history, price];
        return s.copyWith(
          price: price,
          // Grafik son iki yılı gösterir; sınırsız liste belleği şişirir.
          history: history.length > 104
              ? history.sublist(history.length - 104)
              : history,
          heat: math.max(0, s.heat - 1.2),
        );
      }(),
  ];

  return StockBoard(stocks: stocks, pending: nextPending);
}
