import 'dart:convert';

import 'rng.dart';
import 'state.dart';

/// Olay kartı tanımı. Kaynağı `content/events/*.json`.
///
/// Neden JSON: 200 olay yazılacak, içerik kod derlemesi gerektirmesin,
/// paralel yazılsın.
class EventDef {
  const EventDef({
    required this.id,
    required this.title,
    required this.text,
    required this.weight,
    required this.conditions,
    required this.options,
  });

  factory EventDef.fromJson(Map<String, dynamic> json) => EventDef(
        id: json['id'] as String,
        title: json['title'] as String,
        text: json['text'] as String,
        weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
        conditions: EventConditions.fromJson(
          (json['conditions'] as Map<String, dynamic>?) ?? const {},
        ),
        options: [
          for (final o in json['options'] as List)
            EventOption.fromJson(o as Map<String, dynamic>),
        ],
      );

  static List<EventDef> listFromJsonString(String source) => [
        for (final e in jsonDecode(source) as List)
          EventDef.fromJson(e as Map<String, dynamic>),
      ];

  final String id;
  final String title;
  final String text;

  /// Seçim ağırlığı. 1,0 normal; kriz kartları düşük ağırlıkla başlar.
  final double weight;

  final EventConditions conditions;
  final List<EventOption> options;
}

class EventConditions {
  const EventConditions({
    this.minWeek,
    this.maxWeek,
    this.minSuspicion,
    this.maxSuspicion,
    this.minPanic,
    this.schemes = const [],
    this.regimes = const [],
    this.minInvestors,
    this.maxCoverage,
  });

  factory EventConditions.fromJson(Map<String, dynamic> json) =>
      EventConditions(
        minWeek: (json['minWeek'] as num?)?.toInt(),
        maxWeek: (json['maxWeek'] as num?)?.toInt(),
        minSuspicion: (json['minSuspicion'] as num?)?.toDouble(),
        maxSuspicion: (json['maxSuspicion'] as num?)?.toDouble(),
        minPanic: (json['minPanic'] as num?)?.toDouble(),
        schemes: [for (final v in (json['schemes'] as List?) ?? []) v as String],
        regimes: [for (final v in (json['regimes'] as List?) ?? []) v as String],
        minInvestors: (json['minInvestors'] as num?)?.toInt(),
        maxCoverage: (json['maxCoverage'] as num?)?.toDouble(),
      );

  final int? minWeek;
  final int? maxWeek;
  final double? minSuspicion;
  final double? maxSuspicion;
  final double? minPanic;

  /// Boşsa her şemada çıkar. Doluysa yalnız sayılan şema türlerinde.
  /// Kripto borsasında tabela açılışı olmaz.
  final List<String> schemes;

  /// Boşsa her piyasa havasında çıkar.
  final List<String> regimes;

  final int? minInvestors;

  /// Kasa şu orandan az karşılıyorsa. Sıkışmışken gelen kartlar için.
  final double? maxCoverage;

  bool matches(SchemeState s) {
    if (minWeek != null && s.week < minWeek!) return false;
    if (maxWeek != null && s.week > maxWeek!) return false;
    if (minSuspicion != null && s.suspicion < minSuspicion!) return false;
    if (maxSuspicion != null && s.suspicion > maxSuspicion!) return false;
    if (minPanic != null && s.panic < minPanic!) return false;
    if (schemes.isNotEmpty && !schemes.contains(s.typeId)) return false;
    if (regimes.isNotEmpty && !regimes.contains(s.market.regime.name)) {
      return false;
    }
    if (minInvestors != null && s.investorCount < minInvestors!) return false;
    if (maxCoverage != null && s.coverage > maxCoverage!) return false;
    return true;
  }
}

class EventOption {
  const EventOption({required this.label, required this.effects});

  factory EventOption.fromJson(Map<String, dynamic> json) => EventOption(
        label: json['label'] as String,
        effects: EventEffects.fromJson(
          (json['effects'] as Map<String, dynamic>?) ?? const {},
        ),
      );

  final String label;
  final EventEffects effects;
}

/// Bir seçeneğin state'e etkisi. Her alan isteğe bağlı, yoksa sıfır etki.
class EventEffects {
  const EventEffects({
    this.cash = 0,
    this.suspicion = 0,
    this.panic = 0,
    this.promisedRateDelta = 0,
    this.skimDelta = 0,
    this.fixedCostDelta = 0,
    this.channelMult,
    this.channelMultWeeks = 0,
    this.withdrawMult,
    this.withdrawMultWeeks = 0,
  });

  factory EventEffects.fromJson(Map<String, dynamic> json) => EventEffects(
        cash: (json['cash'] as num?)?.toDouble() ?? 0,
        suspicion: (json['suspicion'] as num?)?.toDouble() ?? 0,
        panic: (json['panic'] as num?)?.toDouble() ?? 0,
        promisedRateDelta: (json['promisedRateDelta'] as num?)?.toDouble() ?? 0,
        skimDelta: (json['skimDelta'] as num?)?.toDouble() ?? 0,
        fixedCostDelta: (json['fixedCostDelta'] as num?)?.toDouble() ?? 0,
        channelMult: (json['channelMult'] as num?)?.toDouble(),
        channelMultWeeks: (json['channelMultWeeks'] as num?)?.toInt() ?? 0,
        withdrawMult: (json['withdrawMult'] as num?)?.toDouble(),
        withdrawMultWeeks: (json['withdrawMultWeeks'] as num?)?.toInt() ?? 0,
      );

  final double cash;
  final double suspicion;
  final double panic;
  final double promisedRateDelta;
  final double skimDelta;
  final double fixedCostDelta;
  final double? channelMult;
  final int channelMultWeeks;
  final double? withdrawMult;
  final int withdrawMultWeeks;

  SchemeState applyTo(SchemeState s) {
    final modifiers = [...s.modifiers];
    if (channelMult != null && channelMultWeeks > 0) {
      modifiers.add(TimedModifier(
        kind: ModifierKind.channel,
        multiplier: channelMult!,
        weeksLeft: channelMultWeeks,
      ));
    }
    if (withdrawMult != null && withdrawMultWeeks > 0) {
      modifiers.add(TimedModifier(
        kind: ModifierKind.withdraw,
        multiplier: withdrawMult!,
        weeksLeft: withdrawMultWeeks,
      ));
    }
    return s.copyWith(
      cash: s.cash + cash,
      suspicion: (s.suspicion + suspicion).clamp(0, 100),
      // Panik 1,0'ın altına inmez: sakinden daha sakin yok.
      panic: (s.panic + panic).clamp(1.0, double.infinity),
      promisedRateWeekly:
          (s.promisedRateWeekly + promisedRateDelta).clamp(0.0, 1.0),
      skim: (s.skim + skimDelta).clamp(0.0, 0.9),
      fixedCostWeekly:
          (s.fixedCostWeekly + fixedCostDelta).clamp(0.0, double.infinity),
      modifiers: modifiers,
    );
  }
}

/// Olay havuzundan bu haftanın kartlarını çeker.
class EventEngine {
  EventEngine(this.defs, {this.baseChancePerWeek = 0.34, this.maxPerWeek = 2})
      : _byId = {for (final d in defs) d.id: d};

  final List<EventDef> defs;
  final Map<String, EventDef> _byId;

  /// Herhangi bir haftada olay gelme olasılığı.
  ///
  /// Dikkat: bu, havuzdaki kart sayısından bağımsızdır. Önce uygun kartlar
  /// toplanır, sonra bu şansla kaç kart geleceğine karar verilir. Eskiden her
  /// kart için ayrı zar atılıyordu ve içerik büyüdükçe oyun olay yağmuruna
  /// dönüyordu; içerik eklemek sıklığı değil çeşitliliği artırmalı.
  final double baseChancePerWeek;

  final int maxPerWeek;

  EventDef? byId(String id) => _byId[id];

  /// Koşulu tutan, daha önce gelmemiş kartlar arasından ağırlıklı çekiliş.
  /// Şüphe 60'ın üstünde kriz kartları sıklaşsın diye şans ölçeklenir.
  List<EventDef> draw(SchemeState s, SimRng rng) {
    final eligible = [
      for (final def in defs)
        if (!s.firedEventIds.contains(def.id) &&
            !s.pendingEventIds.contains(def.id) &&
            def.conditions.matches(s))
          def,
    ];
    if (eligible.isEmpty) return const [];

    final pressure = s.suspicion > 60 ? 1.0 + (s.suspicion - 60) / 60 : 1.0;
    var chance = (baseChancePerWeek * pressure).clamp(0.0, 0.9);
    final drawn = <EventDef>[];
    for (var i = 0; i < maxPerWeek; i++) {
      if (rng.nextDouble() >= chance) break;
      final pick = _weightedPick(eligible, rng);
      if (pick == null) break;
      drawn.add(pick);
      eligible.remove(pick);
      // İkinci kart belirgin biçimde daha nadir: aynı haftada iki kriz
      // üst üste gelmesin.
      chance *= 0.35;
    }
    return drawn;
  }

  /// Ağırlıklara göre tek kart seçer.
  EventDef? _weightedPick(List<EventDef> pool, SimRng rng) {
    if (pool.isEmpty) return null;
    final total = pool.fold(0.0, (sum, d) => sum + d.weight);
    if (total <= 0) return pool.first;
    var roll = rng.nextDouble() * total;
    for (final d in pool) {
      roll -= d.weight;
      if (roll <= 0) return d;
    }
    return pool.last;
  }
}
