import 'package:vaat_sim/vaat_sim.dart';

/// Bir manşet: medya akışında görünen tek satır.
class Headline {
  const Headline(this.week, this.text);

  factory Headline.fromJson(Map<String, dynamic> j) =>
      Headline((j['week'] as num).toInt(), j['text'] as String);

  final int week;
  final String text;

  Map<String, dynamic> toJson() => {'week': week, 'text': text};
}

/// Oyuncunun o an nerede olduğu.
enum GamePhase {
  /// Bir şema oynanıyor.
  running,

  /// Bölüm bitti, "aradaki hayat" ekranı: para sayılır, sonraki şema seçilir.
  between,

  /// Kariyer bitti: yakalandın.
  careerOver,
}

/// UI'nın izlediği oyun durumu. Kariyer, şema ve arayüz taslakları.
///
/// Neden taslak alanlar ayrı: vaat kaydıracı oynatılınca sim state'i hemen
/// değişmez, hafta kapanınca hamle olarak gider.
class GameState {
  const GameState({
    required this.career,
    required this.scheme,
    required this.schemeTypeId,
    required this.phase,
    required this.draftRate,
    required this.draftSkim,
    required this.queued,
    required this.answers,
    required this.headlines,
    required this.cashHistory,
    required this.promisedHistory,
    required this.marketHistory,
    required this.offers,
    required this.busy,
  });

  final CareerState career;

  /// Oynanan şema. Kariyer bittiğinde son şemanın kapanış hâli burada kalır,
  /// çünkü sonuç ekranı onun rakamlarını gösterir.
  final SchemeState scheme;
  final String schemeTypeId;

  final GamePhase phase;

  final double draftRate;
  final double draftSkim;

  /// Hafta kapanınca gidecek hamleler.
  final List<PlayerAction> queued;

  /// Bekleyen olay id'si → seçilen seçenek. UI "cevaplandı" göstersin.
  final Map<String, int> answers;

  final List<Headline> headlines;
  final List<double> cashHistory;
  final List<double> promisedHistory;

  /// Piyasa endeksinin hafta hafta seyri. Piyasa sekmesindeki grafik.
  final List<double> marketHistory;

  /// "Aradaki hayat" ekranında sunulan şema teklifleri.
  final List<String> offers;

  /// Haftalar otomatik akarken doğru; buton kilitlenir.
  final bool busy;

  /// Kaydedilen alanlar. Taslak kaydıraçlar ve kuyruktaki hamleler dışarıda:
  /// oyuncu kapattığında henüz uygulanmamış bir hamle kaydedilmemeli.
  Map<String, dynamic> toJson() => {
        'career': careerToJson(career),
        'scheme': schemeToJson(scheme),
        'schemeTypeId': schemeTypeId,
        'phase': phase.name,
        'headlines': [for (final h in headlines) h.toJson()],
        'cashHistory': cashHistory,
        'promisedHistory': promisedHistory,
        'marketHistory': marketHistory,
        'offers': offers,
      };

  factory GameState.fromJson(Map<String, dynamic> j) {
    final scheme = schemeFromJson(j['scheme'] as Map<String, dynamic>);
    return GameState(
      career: careerFromJson(j['career'] as Map<String, dynamic>),
      scheme: scheme,
      schemeTypeId: j['schemeTypeId'] as String,
      phase: GamePhase.values.byName(j['phase'] as String),
      draftRate: scheme.promisedRateWeekly,
      draftSkim: scheme.skim,
      queued: const [],
      answers: const {},
      headlines: [
        for (final raw in j['headlines'] as List)
          Headline.fromJson(raw as Map<String, dynamic>),
      ],
      cashHistory: [
        for (final v in j['cashHistory'] as List) (v as num).toDouble(),
      ],
      promisedHistory: [
        for (final v in j['promisedHistory'] as List) (v as num).toDouble(),
      ],
      marketHistory: [
        for (final v in j['marketHistory'] as List) (v as num).toDouble(),
      ],
      offers: [for (final v in j['offers'] as List) v as String],
      busy: false,
    );
  }

  GameState copyWith({
    CareerState? career,
    SchemeState? scheme,
    String? schemeTypeId,
    GamePhase? phase,
    double? draftRate,
    double? draftSkim,
    List<PlayerAction>? queued,
    Map<String, int>? answers,
    List<Headline>? headlines,
    List<double>? cashHistory,
    List<double>? promisedHistory,
    List<double>? marketHistory,
    List<String>? offers,
    bool? busy,
  }) =>
      GameState(
        career: career ?? this.career,
        scheme: scheme ?? this.scheme,
        schemeTypeId: schemeTypeId ?? this.schemeTypeId,
        phase: phase ?? this.phase,
        draftRate: draftRate ?? this.draftRate,
        draftSkim: draftSkim ?? this.draftSkim,
        queued: queued ?? this.queued,
        answers: answers ?? this.answers,
        headlines: headlines ?? this.headlines,
        cashHistory: cashHistory ?? this.cashHistory,
        promisedHistory: promisedHistory ?? this.promisedHistory,
        marketHistory: marketHistory ?? this.marketHistory,
        offers: offers ?? this.offers,
        busy: busy ?? this.busy,
      );
}
