import 'dart:convert';

/// Bir şema türünün sabit tanımı. Kaynağı `content/schemes.json`.
///
/// Neden veri: kariyer boyunca 6 tür oynanıyor ve hepsi aynı motorla dönüyor.
/// Tür farkı kodda değil, bu dosyadaki çarpanlarda. Yeni tür eklemek JSON'a
/// bir kayıt yazmak demek.
class SchemeType {
  const SchemeType({
    required this.id,
    required this.name,
    required this.pitch,
    required this.cover,
    required this.seedSegment,
    required this.segments,
    required this.startCash,
    required this.startRateWeekly,
    required this.maxRateWeekly,
    required this.fixedCostWeekly,
    required this.withdrawMult,
    required this.suspicionMult,
    required this.channelMult,
    required this.salePremium,
    required this.exitDifficulty,
    required this.marketSensitivity,
    required this.stocks,
    required this.requires,
    required this.tags,
  });

  factory SchemeType.fromJson(Map<String, dynamic> json) => SchemeType(
        id: json['id'] as String,
        name: json['name'] as String,
        pitch: json['pitch'] as String,
        cover: json['cover'] as String,
        seedSegment: json['seedSegment'] as String,
        segments: [for (final s in json['segments'] as List) s as String],
        startCash: (json['startCash'] as num).toDouble(),
        startRateWeekly: (json['startRateWeekly'] as num).toDouble(),
        maxRateWeekly: (json['maxRateWeekly'] as num).toDouble(),
        fixedCostWeekly: (json['fixedCostWeekly'] as num).toDouble(),
        withdrawMult: (json['withdrawMult'] as num).toDouble(),
        suspicionMult: (json['suspicionMult'] as num).toDouble(),
        channelMult: (json['channelMult'] as num).toDouble(),
        salePremium: (json['salePremium'] as num).toDouble(),
        exitDifficulty: (json['exitDifficulty'] as num).toDouble(),
        marketSensitivity:
            (json['marketSensitivity'] as num?)?.toDouble() ?? 1.0,
        stocks: [
          for (final raw in (json['stocks'] as List?) ?? [])
            () {
              final s = raw as Map<String, dynamic>;
              return (
                s['id'] as String,
                s['name'] as String,
                (s['price'] as num).toDouble(),
                (s['float'] as num).toInt(),
              );
            }(),
        ],
        requires: [for (final s in json['requires'] as List) s as String],
        tags: [for (final s in json['tags'] as List) s as String],
      );

  static List<SchemeType> listFromJsonString(String source) => [
        for (final e in jsonDecode(source) as List)
          SchemeType.fromJson(e as Map<String, dynamic>),
      ];

  final String id;
  final String name;

  /// Şema seçim kartında görünen tek cümlelik tanıtım.
  final String pitch;

  /// Dışarıya anlatılan iş. Gazeteci bunu sorgular.
  final String cover;

  /// İlk yatırımcıların geldiği segment, yani "kabile".
  final String seedSegment;

  /// Bu şemada açılabilen segmentler. Kripto borsasına gurbetçi gelmez.
  final List<String> segments;

  final double startCash;
  final double startRateWeekly;

  /// Kaydıracın üst sınırı. Kripto borsasında oyuncu çok daha ileri gidebilir.
  final double maxRateWeekly;

  final double fixedCostWeekly;
  final double withdrawMult;
  final double suspicionMult;
  final double channelMult;

  /// Satışta alıcının ekstre toplamı üzerinden ödediği prim. Üretim kılıfının
  /// tesisi vardır, alıcı fazla verir; yatırım grubunun satılacak bir şeyi yok.
  final double salePremium;

  /// Kaçışın ne kadar iz bıraktığı. Kripto borsası "bakım modu" ile sessizce
  /// kapanır, saadet zincirinden kaçmak zordur çünkü herkes yüzünü bilir.
  final double exitDifficulty;

  /// Piyasa havasının bu şemayı ne kadar etkilediği. Kripto borsası boğada
  /// uçar ayıda çöker; cemaat parası piyasayı pek takmaz.
  final double marketSensitivity;

  /// Oynanabilir hisseler. Boşsa bu şemada borsa katmanı kapalı, piyasa
  /// sekmesi yalnız endeksi gösterir.
  final List<(String, String, double, int)> stocks;

  /// Açılması için gereken kariyer varlıkları. Şimdilik hepsi boş; gerçek
  /// işler ve tanıdıklar geldiğinde burası dolacak.
  final List<String> requires;

  final List<String> tags;
}
