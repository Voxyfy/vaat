import 'dart:convert';

/// Kariyer boyunca satın alınan gerçek işletme.
///
/// Üç işe yarar: kara parayı temize çevirir, şemaya kılıf olur, bazı şema
/// türlerinin kapısını açar. Gerçek vakalarda paravan şirket şüpheyi yıllarca
/// erteliyordu; burada da öyle.
class BusinessType {
  const BusinessType({
    required this.id,
    required this.name,
    required this.pitch,
    required this.price,
    required this.weeklyIncome,
    required this.launderPerWeek,
    required this.suspicionRelief,
    required this.channelBonus,
    required this.unlocks,
  });

  factory BusinessType.fromJson(Map<String, dynamic> j) => BusinessType(
        id: j['id'] as String,
        name: j['name'] as String,
        pitch: j['pitch'] as String,
        price: (j['price'] as num).toDouble(),
        weeklyIncome: (j['weeklyIncome'] as num).toDouble(),
        launderPerWeek: (j['launderPerWeek'] as num).toDouble(),
        suspicionRelief: (j['suspicionRelief'] as num).toDouble(),
        channelBonus: (j['channelBonus'] as num).toDouble(),
        unlocks: [for (final v in j['unlocks'] as List) v as String],
      );

  static List<BusinessType> listFromJsonString(String s) => [
        for (final e in jsonDecode(s) as List)
          BusinessType.fromJson(e as Map<String, dynamic>),
      ];

  final String id;
  final String name;
  final String pitch;
  final double price;

  /// Haftalık kâr veya zarar. Futbol kulübü para yer, döviz bürosu kazandırır.
  final double weeklyIncome;

  /// Haftada ne kadar kara parayı temize çevirebiliyor.
  final double launderPerWeek;

  /// Şüphe birikimini yavaşlatan pay. Eksi değer dikkat çektiği anlamına gelir.
  final double suspicionRelief;

  /// Yeni para akışına kalıcı çarpan.
  final double channelBonus;

  /// Açtığı şema türleri.
  final List<String> unlocks;
}

/// Ağdaki bir kişi. Bir kez satın alınır, sonra iyilik istenir.
class ContactType {
  const ContactType({
    required this.id,
    required this.name,
    required this.pitch,
    required this.price,
    required this.suspicionRelief,
    required this.escapeBonus,
    required this.favorCost,
  });

  factory ContactType.fromJson(Map<String, dynamic> j) => ContactType(
        id: j['id'] as String,
        name: j['name'] as String,
        pitch: j['pitch'] as String,
        price: (j['price'] as num).toDouble(),
        suspicionRelief: (j['suspicionRelief'] as num).toDouble(),
        escapeBonus: (j['escapeBonus'] as num).toDouble(),
        favorCost: (j['favorCost'] as num).toDouble(),
      );

  static List<ContactType> listFromJsonString(String s) => [
        for (final e in jsonDecode(s) as List)
          ContactType.fromJson(e as Map<String, dynamic>),
      ];

  final String id;
  final String name;
  final String pitch;
  final double price;
  final double suspicionRelief;

  /// Kaçışın temiz geçme ihtimaline katkısı.
  final double escapeBonus;

  /// Bölüm içinde iyilik istemenin bedeli.
  final double favorCost;
}

/// Kaçış planının bir parçası. Hepsi tamamsa kaçış planlı sayılır.
class EscapePart {
  const EscapePart({
    required this.id,
    required this.name,
    required this.pitch,
    required this.price,
    required this.weight,
  });

  factory EscapePart.fromJson(Map<String, dynamic> j) => EscapePart(
        id: j['id'] as String,
        name: j['name'] as String,
        pitch: j['pitch'] as String,
        price: (j['price'] as num).toDouble(),
        weight: (j['weight'] as num).toDouble(),
      );

  static List<EscapePart> listFromJsonString(String s) => [
        for (final e in jsonDecode(s) as List)
          EscapePart.fromJson(e as Map<String, dynamic>),
      ];

  final String id;
  final String name;
  final String pitch;
  final double price;

  /// Kaçış hazırlığına katkısı. Toplamları 1,0 eder.
  final double weight;
}

/// Sonraki şemaya girerken alınan ortak.
enum PartnerKind { capital, political, celebrity, insider }

extension PartnerTraits on PartnerKind {
  /// Ortağın koyduğu sermaye, oyuncunun kendi sermayesine oranla.
  double get capitalShare => switch (this) {
        PartnerKind.capital => 0.8,
        PartnerKind.political => 0.2,
        PartnerKind.celebrity => 0.1,
        PartnerKind.insider => 0.0,
      };

  /// Kârdan aldığı pay. Skim'den düşülür.
  double get profitCut => switch (this) {
        PartnerKind.capital => 0.35,
        PartnerKind.political => 0.25,
        PartnerKind.celebrity => 0.2,
        PartnerKind.insider => 0.15,
      };

  /// Şüphe birikimine çarpan. Siyasi ortak baskılar, ünlü ortak dikkat çeker.
  double get suspicionFactor => switch (this) {
        PartnerKind.capital => 1.0,
        PartnerKind.political => 0.6,
        PartnerKind.celebrity => 1.25,
        PartnerKind.insider => 0.9,
      };

  /// Yeni para akışına çarpan.
  double get channelFactor => switch (this) {
        PartnerKind.capital => 1.1,
        PartnerKind.political => 1.15,
        PartnerKind.celebrity => 1.6,
        PartnerKind.insider => 1.0,
      };

  /// Ortağın ihanet eşiği: şüphe bunu geçince konuşmayı düşünmeye başlar.
  double get betrayalThreshold => switch (this) {
        PartnerKind.capital => 70,
        PartnerKind.political => 85,
        PartnerKind.celebrity => 55,
        PartnerKind.insider => 60,
      };
}
