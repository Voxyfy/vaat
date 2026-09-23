import 'dart:math' as math;

import 'assets.dart';
import 'scheme_type.dart';
import 'state.dart';

/// Bir bölümün kariyer defterine düşen satırı.
class ChapterRecord {
  const ChapterRecord({
    required this.schemeId,
    required this.schemeName,
    required this.weeks,
    required this.end,
    required this.collected,
    required this.victims,
    required this.tookHome,
  });

  final String schemeId;
  final String schemeName;
  final int weeks;
  final SchemeEnd end;
  final double collected;
  final int victims;

  /// Bu bölümden kariyere taşınan para.
  final double tookHome;
}

/// Kariyerin nasıl bittiği. Oyuncu kazanmaz, yalnız daha iyi çekilir;
/// her sonun skor çarpanı bunu söyler.
enum CareerEnding {
  /// Planlı kaçış: iadesi olmayan ülke, para önden gitmiş. Sessiz yaşa.
  farm,

  /// Sahte kimlikle komşu ülkede. Ucuz ama tedirgin.
  balkan,

  /// Faizsiz holdingi satıp satıp yaşattın; şirket ayakta, sen "iş insanı".
  corporate,

  /// Herkesi verdin. Ceza yarıya, para gider.
  informant,

  /// Krizde kaçmadın, aileye anlattın. Tek ahlaki son, skor sıfır.
  confession,

  /// Para bitti, yabancı bir şehirde kimsesiz.
  poverty,

  /// Yakalandın. Baskın veya kasa çöküşü buraya çıkar.
  prison,
}

extension CareerEndingTraits on CareerEnding {
  /// Skor çarpanı. Sıfır olanlar "kaybedilmiş" değil, hikâyesi farklı sonlar.
  double get multiplier => switch (this) {
        CareerEnding.farm => 1.0,
        CareerEnding.balkan => 0.8,
        CareerEnding.corporate => 1.5,
        CareerEnding.informant => 0.5,
        CareerEnding.confession => 0.0,
        CareerEnding.poverty => 0.1,
        CareerEnding.prison => 0.0,
      };

  /// Oyuncunun kendi seçtiği sonlar. Hapis seçilmez, başa gelir.
  bool get voluntary => this != CareerEnding.prison;
}

/// Kariyer durumu. Şemalar gelir geçer, bu kalır.
class CareerState {
  const CareerState({
    required this.cleanMoney,
    required this.dirtyMoney,
    required this.record,
    required this.playedSchemeIds,
    required this.chapters,
    required this.businesses,
    required this.contacts,
    required this.escapeParts,
    required this.partner,
    required this.over,
    required this.overReason,
    this.ending,
  });

  const CareerState.fresh()
      : cleanMoney = 0,
        dirtyMoney = 0,
        record = 0,
        playedSchemeIds = const [],
        chapters = const [],
        businesses = const [],
        contacts = const [],
        escapeParts = const [],
        partner = null,
        over = false,
        overReason = null,
        ending = null;

  /// Aklanmış para. Yeni şemaya sermaye olarak tam girer.
  final double cleanMoney;

  /// Kara para. Sermaye olarak girerken kısmen yakılır, çünkü taşınması risk.
  final double dirtyMoney;

  /// Geçmiş dosyası, 0 ile 100. Yakalanmamış suçların toplamı. Her yeni şema
  /// bu kadar yüksek şüpheden başlar, yani kariyer kendi sonunu getirir.
  final double record;

  final List<String> playedSchemeIds;
  final List<ChapterRecord> chapters;

  /// Sahip olunan gerçek işletmelerin id'leri.
  final List<String> businesses;

  /// Ağdaki kişilerin id'leri.
  final List<String> contacts;

  /// Hazır kaçış planı parçalarının id'leri.
  final List<String> escapeParts;

  /// Sonraki şemaya girilen ortak. Bölüm bitince sıfırlanır.
  final PartnerKind? partner;

  final bool over;
  final String? overReason;

  /// Kariyer bitmişse nasıl bittiği. `over` doğruyken boş kalmaz.
  final CareerEnding? ending;

  int get chapter => chapters.length + 1;

  /// Kaçış hazırlığı, 0 ile 1 arası. Parçaların ağırlıkları toplanır.
  /// Hazırlıksız kaçan parasının çoğunu yolda bırakır.
  double escapeReadiness(List<EscapePart> all, List<ContactType> allContacts) {
    var total = 0.0;
    for (final part in all) {
      if (escapeParts.contains(part.id)) total += part.weight;
    }
    for (final c in allContacts) {
      if (contacts.contains(c.id)) total += c.escapeBonus;
    }
    return total.clamp(0.0, 1.0);
  }

  /// İşletmelerin haftada temize çevirebildiği toplam.
  double launderCapacity(List<BusinessType> all) {
    var total = 0.0;
    for (final b in all) {
      if (businesses.contains(b.id)) total += b.launderPerWeek;
    }
    return total;
  }

  /// İşletme ve tanıdıkların şüpheyi yavaşlatma payı. 1,0 etkisiz.
  double suspicionShield(
      List<BusinessType> allBiz, List<ContactType> allContacts) {
    var relief = 0.0;
    for (final b in allBiz) {
      if (businesses.contains(b.id)) relief += b.suspicionRelief;
    }
    for (final c in allContacts) {
      if (contacts.contains(c.id)) relief += c.suspicionRelief;
    }
    // Koruma birikir ama tamamen bağışıklık kazandırmaz.
    return (1 - relief * 0.25).clamp(0.35, 1.4);
  }

  /// İşletmelerin yeni para akışına kalıcı katkısı.
  double channelBonus(List<BusinessType> all) {
    var mult = 1.0;
    for (final b in all) {
      if (businesses.contains(b.id)) mult *= b.channelBonus;
    }
    return mult;
  }

  /// İşletmelerin haftalık net kâr veya zararı.
  double weeklyBusinessIncome(List<BusinessType> all) {
    var total = 0.0;
    for (final b in all) {
      if (businesses.contains(b.id)) total += b.weeklyIncome;
    }
    return total;
  }

  /// Sahip olunan işletmelerin açtığı şema türleri.
  Set<String> unlockedSchemes(List<BusinessType> all) => {
        for (final b in all)
          if (businesses.contains(b.id)) ...b.unlocks,
      };

  /// Yeni şemaya konulabilecek sermaye. Kara paranın üçte biri yolda erir:
  /// nakit taşımak, aracı, komisyon.
  double get usableCapital => cleanMoney + dirtyMoney * 0.66;

  int get totalWeeks => chapters.fold(0, (sum, c) => sum + c.weeks);
  int get totalVictims => chapters.fold(0, (sum, c) => sum + c.victims);
  double get totalCollected =>
      chapters.fold(0.0, (sum, c) => sum + c.collected);

  /// Kariyer skoru. Kare kök özgür kalmayı ödüllendirir ama sonsuz saklanmayı
  /// paradan değerli kılmaz. Bitmemiş kariyerde çarpan 1: oyuncu "şu an
  /// çekilsem ne yazar" diye bakabilsin.
  double get score {
    final money = cleanMoney + dirtyMoney * 0.3;
    final base = money * math.sqrt(math.max(totalWeeks, 1) / 52);
    return base * (ending?.multiplier ?? 1.0);
  }

  /// Hapis sonunda ekrana yazılan ceza. Türkiye usulü: her mağdur ayrı suç,
  /// toplam binlerce yıl. Gerçek vakalarda mağdur başına 5 yıl civarı çıkıyor.
  int get prisonYears => math.max(totalVictims * 5, 3);

  /// Faizsiz holdingi kaç kez satıp yeniden kurdun. "Kurumsal ölümsüzlük"
  /// sonunun anahtarı.
  int get holdingSales => chapters
      .where((c) => c.schemeId == 'profitShareHolding' && c.end == SchemeEnd.sold)
      .length;

  /// Oyuncunun şu an seçebileceği sonlar. Koşullar oyuncuya da gösterilir,
  /// bu yüzden her biri tek bir somut şeye bakar.
  List<CareerEnding> availableEndings() => [
        for (final e in CareerEnding.values)
          if (e.voluntary && canEnd(e)) e,
      ];

  bool canEnd(CareerEnding e) => switch (e) {
        // Ülke ayarlanmış ve para önden gitmiş olmalı; yanında nakitle
        // havalimanına gitmek plan değil.
        CareerEnding.farm =>
          escapeParts.contains('country') && escapeParts.contains('offshore'),
        CareerEnding.balkan => escapeParts.contains('passport'),
        CareerEnding.corporate => holdingSales >= 2,
        // İtirafçı olmak için savcının seni istemesi gerekir.
        CareerEnding.informant => record >= 60,
        // İtiraf bir kriz kararı: dosya ağırken anlam taşır.
        CareerEnding.confession => record >= 50,
        // Sefalet: kaçacak paran yok.
        CareerEnding.poverty => usableCapital < 100000,
        CareerEnding.prison => false,
      };

  /// Kariyeri oyuncunun seçtiği sonla kapatır. Her sonun parayla ilişkisi
  /// farklı; skor çarpanı ayrı, buradaki kesinti ayrı.
  CareerState retire(CareerEnding e) {
    assert(e.voluntary && canEnd(e));
    var clean = cleanMoney;
    var dirty = dirtyMoney;
    switch (e) {
      case CareerEnding.informant:
        // Anlaşma: para iade edilir, tanık koruma maaşıyla yaşarsın.
        clean *= 0.2;
        dirty = 0;
      case CareerEnding.confession:
        // Her şeyi geri verdin. Skor zaten sıfır, para da öyle.
        clean = 0;
        dirty = 0;
      case CareerEnding.balkan:
        // Sahte kimlik pahalı ve kara para sınırda erir.
        dirty *= 0.7;
      case CareerEnding.farm:
      case CareerEnding.corporate:
      case CareerEnding.poverty:
      case CareerEnding.prison:
        break;
    }
    return copyWith(
      cleanMoney: clean,
      dirtyMoney: dirty,
      over: true,
      ending: e,
      clearPartner: true,
    );
  }

  CareerState copyWith({
    double? cleanMoney,
    double? dirtyMoney,
    double? record,
    List<String>? playedSchemeIds,
    List<ChapterRecord>? chapters,
    List<String>? businesses,
    List<String>? contacts,
    List<String>? escapeParts,
    PartnerKind? partner,
    bool clearPartner = false,
    bool? over,
    String? overReason,
    CareerEnding? ending,
  }) =>
      CareerState(
        cleanMoney: cleanMoney ?? this.cleanMoney,
        dirtyMoney: dirtyMoney ?? this.dirtyMoney,
        record: record ?? this.record,
        playedSchemeIds: playedSchemeIds ?? this.playedSchemeIds,
        chapters: chapters ?? this.chapters,
        businesses: businesses ?? this.businesses,
        contacts: contacts ?? this.contacts,
        escapeParts: escapeParts ?? this.escapeParts,
        partner: clearPartner ? null : (partner ?? this.partner),
        over: over ?? this.over,
        overReason: overReason ?? this.overReason,
        ending: ending ?? this.ending,
      );
}

/// Bir bölümün kapanışı: şemadan çıkan para ve iz kariyere yazılır.
///
/// Neden ayrı fonksiyon: her sonun parası ve bedeli farklı, bu tablo oyunun
/// asıl kararını (ne zaman ve nasıl çıkacağın) taşıyor.
CareerState closeChapter({
  required CareerState career,
  required SchemeState scheme,
  required SchemeType type,
  double escapeReadiness = 0,
}) {
  final end = scheme.end;
  if (end == null) return career;

  var clean = career.cleanMoney;
  var dirty = career.dirtyMoney;
  var record = career.record;
  var tookHome = 0.0;

  switch (end) {
    case SchemeEnd.fled:
      // Kasa ve cep birlikte gelir, ama hazırlıksız kaçışta çoğu yolda kalır:
      // nakit taşımak, acele bilet, aracıya kaptırılan pay.
      final gross = math.max(scheme.cash, 0) + scheme.totalSkimmed;
      final kept = 0.35 + 0.65 * escapeReadiness.clamp(0.0, 1.0);
      tookHome = gross * kept;
      dirty += tookHome;
      // Hazırlıklı kaçış daha az iz bırakır: hikâyen hazır, aranman gecikir.
      record += 25 * type.exitDifficulty * (1 - 0.4 * escapeReadiness);
    case SchemeEnd.sold:
      tookHome = saleValue(scheme, type);
      clean += tookHome;
      // Satış sözleşmeli: adın kâğıtta kalır ama suç henüz görünmez.
      record += 8;
      dirty += scheme.totalSkimmed;
    case SchemeEnd.handedOver:
      // Firma devredildi: kasadaki paraya dokunamazsın, yalnız cebin kalır.
      tookHome = scheme.totalSkimmed;
      dirty += tookHome;
      record += 12;
    case SchemeEnd.bankRun:
    case SchemeEnd.raid:
      record = 100;
  }

  final chapter = ChapterRecord(
    schemeId: type.id,
    schemeName: type.name,
    weeks: scheme.week,
    end: end,
    collected: scheme.totalInflow,
    victims: scheme.investorCount,
    tookHome: tookHome,
  );

  return career.copyWith(
    cleanMoney: clean,
    dirtyMoney: dirty,
    record: record.clamp(0, 100),
    playedSchemeIds: [...career.playedSchemeIds, type.id],
    chapters: [...career.chapters, chapter],
    // Kaçış planı harcanır: bir sonraki sefere yeniden hazırlanman gerekir.
    escapeParts: end == SchemeEnd.fled ? const [] : career.escapeParts,
    clearPartner: true,
    over: end.endsCareer,
    ending: end.endsCareer ? CareerEnding.prison : null,
    overReason: switch (end) {
      SchemeEnd.bankRun => 'Kasa boşaldı, kalabalık kapıda. Kaçacak yer yoktu.',
      SchemeEnd.raid => 'Savcılık kapıyı kırdı. Kariyer burada bitti.',
      _ => null,
    },
  );
}

/// Alıcının firmaya biçtiği değer.
///
/// Alıcı gerçek deliği görmez, kasayı ve büyüklüğü görür. Ama şüphe yüksekse
/// pazarlık eder: kimse gazetelik bir şirketi tam fiyattan almaz.
double saleValue(SchemeState scheme, SchemeType type) {
  final base = math.max(scheme.cash, 0) * 0.8 +
      scheme.promisedTotal * type.salePremium;
  final discount = (1 - scheme.suspicion / 100).clamp(0.2, 1.0);
  return base * discount;
}

/// Firma satılabilir mi. Alıcı defterlere bakar: kasa çok boşsa veya ortalık
/// çok karışmışsa masadan kalkar.
bool canSell(SchemeState scheme, SchemeType type) =>
    !scheme.isOver &&
    scheme.week >= 8 &&
    scheme.coverage >= 0.35 &&
    scheme.suspicion < 55 &&
    type.salePremium > 0;

/// Devir her zaman mümkün, yeter ki ortalık tam yanmasın. Birini ikna etmek
/// için ona hâlâ bir gelecek gösterebilmen lazım.
bool canHandOver(SchemeState scheme) =>
    !scheme.isOver && scheme.week >= 6 && scheme.suspicion < 80;
