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
        overReason = null;

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

  /// Kariyer skoru. Kare kök özgür kalmayı ödüllendirir ama sonsuz saklanmayı
  /// paradan değerli kılmaz.
  double get score {
    final money = cleanMoney + dirtyMoney * 0.3;
    final weeks = chapters.fold(0, (sum, c) => sum + c.weeks);
    return money * math.sqrt(math.max(weeks, 1) / 52);
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
