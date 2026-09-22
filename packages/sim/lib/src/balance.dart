import 'dart:convert';

/// Denge parametreleri. Kaynağı `content/balance.json`.
///
/// Neden kodda sabit yok: tasarımcı denge değiştirirken derleme yapmasın,
/// aynı motor farklı şema türleri için farklı JSON ile koşabilsin.
class BalanceConfig {
  const BalanceConfig({
    required this.realReturnWeekly,
    required this.baseWithdrawWeekly,
    required this.referenceRateWeekly,
    required this.inflow,
    required this.panic,
    required this.suspicion,
    required this.segments,
  });

  factory BalanceConfig.fromJson(Map<String, dynamic> json) {
    final segmentsJson = json['segments'] as Map<String, dynamic>;
    return BalanceConfig(
      realReturnWeekly: (json['realReturnWeekly'] as num).toDouble(),
      baseWithdrawWeekly: (json['baseWithdrawWeekly'] as num).toDouble(),
      referenceRateWeekly: (json['referenceRateWeekly'] as num).toDouble(),
      inflow: InflowConfig.fromJson(json['inflow'] as Map<String, dynamic>),
      panic: PanicConfig.fromJson(json['panic'] as Map<String, dynamic>),
      suspicion:
          SuspicionConfig.fromJson(json['suspicion'] as Map<String, dynamic>),
      segments: {
        for (final entry in segmentsJson.entries)
          entry.key: SegmentConfig.fromJson(
            entry.key,
            entry.value as Map<String, dynamic>,
          ),
      },
    );
  }

  factory BalanceConfig.fromJsonString(String source) =>
      BalanceConfig.fromJson(jsonDecode(source) as Map<String, dynamic>);

  /// Paranın gerçekten kazandığı haftalık getiri. Çoğu şemada sıfır.
  final double realReturnWeekly;

  /// Ekstre bakiyesine uygulanan taban haftalık çekim oranı.
  final double baseWithdrawWeekly;

  /// "Normal" sayılan haftalık vaat. Üstü şüphe üretir, altı cazibe kaybettirir.
  final double referenceRateWeekly;

  final InflowConfig inflow;
  final PanicConfig panic;
  final SuspicionConfig suspicion;
  final Map<String, SegmentConfig> segments;
}

class InflowConfig {
  const InflowConfig({
    required this.socialProofFloor,
    required this.rateAppealExponent,
    required this.rateAppealMin,
    required this.rateAppealMax,
    required this.credibilityFalloff,
  });

  factory InflowConfig.fromJson(Map<String, dynamic> json) => InflowConfig(
        socialProofFloor: (json['socialProofFloor'] as num).toInt(),
        rateAppealExponent: (json['rateAppealExponent'] as num).toDouble(),
        rateAppealMin: (json['rateAppealMin'] as num).toDouble(),
        rateAppealMax: (json['rateAppealMax'] as num).toDouble(),
        credibilityFalloff: (json['credibilityFalloff'] as num).toDouble(),
      );

  /// Sıfır yatırımcıyla lojistik akış sıfır olur; bu taban, ilk müşterileri
  /// "kabile" saymanın karşılığı.
  final int socialProofFloor;
  final double rateAppealExponent;
  final double rateAppealMin;
  final double rateAppealMax;

  /// Vaat, segmentin inanabileceği sınırı aşınca cazibe bu hızla erir.
  final double credibilityFalloff;
}

class PanicConfig {
  const PanicConfig({
    required this.missedPaymentStep,
    required this.bankRunMultiplier,
    required this.decayPerWeek,
    required this.marketingRelief,
  });

  factory PanicConfig.fromJson(Map<String, dynamic> json) => PanicConfig(
        missedPaymentStep: (json['missedPaymentStep'] as num).toDouble(),
        bankRunMultiplier: (json['bankRunMultiplier'] as num).toDouble(),
        decayPerWeek: (json['decayPerWeek'] as num).toDouble(),
        marketingRelief: (json['marketingRelief'] as num).toDouble(),
      );

  final double missedPaymentStep;
  final double bankRunMultiplier;
  final double decayPerWeek;
  final double marketingRelief;
}

class SuspicionConfig {
  const SuspicionConfig({
    required this.rateExcessPerUnit,
    required this.missedPayment,
    required this.bankRun,
    required this.marketingPerThousand,
    required this.decayPerWeek,
    required this.raidThreshold,
  });

  factory SuspicionConfig.fromJson(Map<String, dynamic> json) =>
      SuspicionConfig(
        rateExcessPerUnit: (json['rateExcessPerUnit'] as num).toDouble(),
        missedPayment: (json['missedPayment'] as num).toDouble(),
        bankRun: (json['bankRun'] as num).toDouble(),
        marketingPerThousand: (json['marketingPerThousand'] as num).toDouble(),
        decayPerWeek: (json['decayPerWeek'] as num).toDouble(),
        raidThreshold: (json['raidThreshold'] as num).toDouble(),
      );

  final double rateExcessPerUnit;
  final double missedPayment;
  final double bankRun;
  final double marketingPerThousand;
  final double decayPerWeek;
  final double raidThreshold;
}

/// Bir yatırımcı segmentinin sabit özellikleri.
class SegmentConfig {
  const SegmentConfig({
    required this.id,
    required this.name,
    required this.market,
    required this.ticket,
    required this.channelBase,
    required this.withdrawMult,
    required this.panicMult,
    required this.maxCredibleRateWeekly,
  });

  factory SegmentConfig.fromJson(String id, Map<String, dynamic> json) =>
      SegmentConfig(
        id: id,
        name: json['name'] as String,
        market: (json['market'] as num).toInt(),
        ticket: (json['ticket'] as num).toDouble(),
        channelBase: (json['channelBase'] as num).toDouble(),
        withdrawMult: (json['withdrawMult'] as num).toDouble(),
        panicMult: (json['panicMult'] as num).toDouble(),
        maxCredibleRateWeekly:
            (json['maxCredibleRateWeekly'] as num).toDouble(),
      );

  final String id;
  final String name;

  /// Ulaşılabilir toplam kişi sayısı. Havuz doyunca akış durur; Ponzi'yi
  /// çökerten şey tam olarak bu plato.
  final int market;

  /// Ortalama yatırım tutarı.
  final double ticket;

  /// Kanal gücü. Pazarlama ve ünlü reklamı bunu çarpar.
  final double channelBase;

  /// Segmentin taban çekim oranına çarpanı. Gurbetçi az çeker, kripto genci çok.
  final double withdrawMult;

  /// Panik yükselince bu segment ne kadar sert tepki verir.
  final double panicMult;

  /// Bu haftalık vaadin üstü segment için "fazla iyi", cazibe düşer.
  final double maxCredibleRateWeekly;
}
