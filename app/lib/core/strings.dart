/// Tüm kullanıcı metinleri burada. Neden: hiçbir string widget içinde
/// hardcoded kalmasın, İngilizce sürümde tek dosya değişsin. Şimdilik
/// yalnızca Türkçe; gerçek i18n altyapısı yerelleştirme başlarken gelir.
abstract final class Tr {
  static const appTitle = 'Vaat';
  static const appSubtitle = 'Dolandırıcı Kariyeri';

  // Öğretici
  static const onboardingSkip = 'Geç';
  static const onboardingNext = 'Devam';
  static const onboardingStart = 'Başla';
  static const onboardingReplay = 'Nasıl oynanır?';
  static const onboardingPages = <(String, String)>[
    (
      'Bu bir dolandırıcılık oyunu.',
      'Bir yatırım şirketi kurarsın. Şirketin hiçbir şey üretmez. '
          'Yatırımcılara yüksek getiri vaat edersin, eski yatırımcıların getirisini yenilerin parasıyla ödersin. '
          'Buna Ponzi denir ve hiçbiri sonsuza dek sürmez.',
    ),
    (
      'Kazanmak yok.',
      'Her şema batar. Tek soru ne zaman ve senin o sırada nerede olacağın. '
          'Amaç mümkün olduğu kadar uzun ayakta kalmak, mümkün olduğu kadar çok parayı cebe atmak ve batmadan önce kaçmak.',
    ),
    (
      'İki sayıya bak.',
      'Karşılama: kasadaki gerçek para, yatırımcıların sahip olduğunu sandığı paranın yüzde kaçı. Düştükçe tek kötü haber seni bitirir.\n\n'
          'Şüphe: gazeteci, savcı, ihbarcı. 100 olursa baskın.',
    ),
    (
      'Bu bir hicivdir.',
      'Yatırım tavsiyesi değildir. Gerçek hayatta yüksek ve düzenli getiri vaat eden biriyle karşılaşırsanız bu oyunu hatırlayın ve SPK\'ya sorun.',
    ),
  ];

  // HUD
  static const week = 'Hafta';
  static const chapterShort = 'B';
  static const coverage = 'Karşılama';
  static const suspicion = 'Şüphe';
  static const endWeek = 'Hafta kapat';
  static const endWeekBusy = 'Akıyor…';
  static const schemeOver = 'Şema bitti';

  // Tablar
  static const tabOffice = 'Ofis';
  static const tabPool = 'Havuz';
  static const tabMarket = 'Piyasa';
  static const tabMedia = 'Medya';
  static const tabProtection = 'Koruma';

  // Ofis
  static const pendingEvents = 'Masandaki dosyalar';
  static const noEvents = 'Sessiz bir hafta. Kimse kapıyı çalmadı.';
  static const answered = 'Cevaplandı';

  // Havuz
  static const realCash = 'Gerçek kasa';
  static const promisedTotal = 'Ekstrelerde yazan';
  static const hole = 'Delik';
  static const investors = 'Yatırımcı';
  static const promisedRate = 'Vaat edilen haftalık getiri';
  static const promisedRateMonthly = 'aylık yaklaşık';
  static const skim = 'Cebe atılan pay';
  static const pocket = 'Cep';
  static const segments = 'Kanallar';
  static const openChannel = 'Kanalı aç';
  static const channelOpen = 'Açık';
  static const channelClosed = 'Kapalı';
  static const ticket = 'bilet';
  static const chartTitle = 'Kasa ve ekstre';

  // Piyasa
  static const marketIndex = 'Piyasa endeksi';
  static const marketRegime = 'Hava';
  static const marketBull = 'YÜKSELİŞ';
  static const marketNormal = 'SAKİN';
  static const marketBear = 'TEDİRGİN';
  static const marketCrash = 'PANİK';
  static const marketBullNote =
      'Herkes yatırımcı. Para akıyor, kimse çekmek istemiyor. Büyümek için en iyi zaman.';
  static const marketNormalNote =
      'Sıradan haftalar. Akış da çekim de olağan seyrinde.';
  static const marketBearNote =
      'Tedirginlik var. Yeni para yavaşladı, çekimler arttı. Rezervini kolla.';
  static const marketCrashNote =
      'Panik. Akış neredeyse durdu, herkes aynı anda nakit istiyor. Ponzi\'leri genelde bu öldürür.';
  static const marketSensitivity = 'Bu şemanın piyasa duyarlılığı';
  static const marketSensLow = 'düşük';
  static const marketSensMid = 'orta';
  static const marketSensHigh = 'yüksek';
  static const marketInflowEffect = 'Yeni para';
  static const marketWithdrawEffect = 'Çekim';
  static const marketWeekChange = 'Bu hafta';
  static const marketHistory = 'Endeks geçmişi';

  // Borsa
  static const stockBoard = 'Hisseler';
  static const stockNoBoard =
      'Bu şemada borsa oynatmıyorsun. Piyasa yine de akışını ve çekimlerini belirliyor.';
  static const stockPrice = 'Fiyat';
  static const stockPosition = 'Pozisyon';
  static const stockHeat = 'İz';
  static const stockHeatNote =
      'Manipülasyon iz bırakır. Denetleyici en sıcak kâğıda bakar, iz zamanla söner.';
  static const stockBuy = 'AL';
  static const stockSell = 'SAT';
  static const stockLot = 'lot';
  static const stockProfit = 'Kâr';
  static const stockLoss = 'Zarar';
  static const stockPortfolio = 'Portföy';
  static const stockManipulate = 'Operasyon';
  static const manipPump = 'Pompala ve boşalt';
  static const manipWash = 'Sahte hacim';
  static const manipSpoof = 'Sahte emir';
  static const manipTape = 'Kapanış çizme';
  static const manipPumpNote =
      'Fiyat sert sıçrar, iki hafta içinde geri iner. En büyük iz.';
  static const manipWashNote =
      'Kendi kendine alıp sat. Hacim görünür, fiyat az oynar.';
  static const manipSpoofNote =
      'İptal edilecek büyük emirlerle fiyatı it. Ucuz, kısa ömürlü.';
  static const manipTapeNote =
      'Kapanışa yakın küçük işlemler. Yavaş, sessiz, uzun ömürlü.';
  static const manipCost = 'Maliyet';

  // Medya
  static const headlines = 'Manşetler';
  static const marketing = 'Reklam kampanyası';
  static const marketingHint = 'Bu hafta kanal gücünü artırır, biraz dikkat çeker.';
  static const marketingSmall = '50 bin';
  static const marketingLarge = '250 bin';
  static const noHeadlines = 'Henüz kimse senden bahsetmiyor.';

  // Koruma
  static const suspicionDetail = 'Şüphe barı';
  static const panic = 'Panik';
  static const bankRun = 'Toplu çekim sürüyor';
  static const flee = 'KAÇ';
  static const fleeHint = 'Basılı tut. Kasa ve cep yanına gelir, yüzün tanınır.';
  static const fleeConfirmTitle = 'Kaçıyor musun?';
  static const fleeConfirmBody =
      'Şema biter. Kasadaki para ve cebindeki para yanına gelir. Geri dönüş yok.';
  static const cancel = 'Vazgeç';
  static const confirmFlee = 'Kaç';

  // Şema sonu ve kariyer
  static const newspaperName = 'Sabah Vaadi';
  static const endBankRun = 'BATTI';
  static const endRaid = 'BASKIN';
  static const endFled = 'KAYIP';
  static const endSold = 'SATILDI';
  static const endHandedOver = 'DEVREDİLDİ';
  static const endSubBankRun = 'Ofis önünde kuyruk, kasa boş.';
  static const endSubRaid = 'Şüphe barı doldu, savcılık kapıda.';
  static const endSubFled = 'Kurucu ortadan kayboldu, telefonlar cevapsız.';
  static const endSubSold = 'Firma el değiştirdi. Yeni sahibi henüz gülümsüyor.';
  static const endSubHandedOver =
      'Yönetim devredildi. İmza artık başkasının, defterler aynı.';
  static const totalInflow = 'Toplanan';
  static const totalPaid = 'Ödenen';
  static const victims = 'Mağdur';
  static const tookHome = 'Yanına aldığın';
  static const realWorldNote =
      'Gerçek Ponzi\'lerin medyan ömrü 3,1 yıl. Mağdur iadesi genellikle sıfıra yakın.';

  // Aradaki hayat
  static const betweenTitle = 'Aradaki hayat';
  static const chapter = 'Bölüm';
  static const cleanMoney = 'Temiz para';
  static const dirtyMoney = 'Kara para';
  static const usableCapital = 'Sonraki şemaya sermaye';
  static const dirtyNote =
      'Kara paranın bir kısmı yolda erir: nakit taşımak, aracı, komisyon.';
  static const record = 'Geçmiş dosyası';
  static const recordNote =
      'Yakalanmamış işlerin toplamı. Yeni şema bu kadar yüksek şüpheden başlar.';
  static const chooseScheme = 'Sıradaki iş';
  static const chooseSchemeNote = 'Birini seç. Diğerleri masadan kalkar.';
  static const schemeCover = 'Kılıf';
  static const schemeStartRate = 'Başlangıç vaadi';
  static const schemeCeiling = 'Vaat tavanı';
  static const schemeStart = 'Kur';
  static const careerLog = 'Kariyer defteri';

  // Aradaki hayat: varlıklar
  static const laundering = 'Aklama';
  static const launderingNote =
      'Kara para hafta hafta temize geçer. Kapasiteyi işletmeler belirler.';
  static const launderCapacity = 'Haftalık kapasite';
  static const noLaunderCapacity =
      'Aklama kapasiten yok. Kara para sermayeye girerken üçte biri eriyor.';
  static const businesses = 'Gerçek işler';
  static const businessesNote =
      'Paravan şirket şüpheyi yıllarca erteler. Bazıları yeni şema türlerinin kapısını açar.';
  static const contactsTitle = 'Tanıdıklar';
  static const contactsNote =
      'Bir kez alınır, kariyer boyunca kalır. Kimi şüpheyi bastırır, kimi kaçışı kolaylaştırır.';
  static const escapePlan = 'Kaçış planı';
  static const escapePlanNote =
      'Hazırlıksız kaçan parasının çoğunu yolda bırakır. Plan kaçışta harcanır.';
  static const escapeReadiness = 'Hazırlık';
  static const partner = 'Ortak';
  static const partnerNote =
      'Sonraki şemaya ortakla girebilirsin. Sermaye veya koruma getirir, kârdan pay alır.';
  static const partnerNone = 'Ortak yok';
  static const partnerCapital = 'Sermaye ortağı';
  static const partnerPolitical = 'Siyasi ortak';
  static const partnerCelebrity = 'Ünlü ortak';
  static const partnerInsider = 'Eski ekipten biri';
  static const partnerCapitalNote =
      'Sermayeyi katlar, kârın üçte birinden fazlasını alır.';
  static const partnerPoliticalNote =
      'Şüpheyi ciddi biçimde bastırır. Karşılığında düzenli pay ister.';
  static const partnerCelebrityNote =
      'Yatırımcı akışını katlar, dikkat de çeker. En çabuk konuşan ortak.';
  static const partnerInsiderNote =
      'Ucuz ve sadık, ama geçmişini bilir.';
  static const owned = 'Var';
  static const buy = 'Al';
  static const notEnoughMoney = 'Temiz para yetmiyor';
  static const unlocksLabel = 'Açar';
  static const weeklyIncomeLabel = 'Haftalık';
  static const launderLabel = 'Aklama';
  static const shieldLabel = 'Kalkan';

  // Kariyer sonu
  static const careerOverTitle = 'KARİYER BİTTİ';
  static const careerScore = 'Skor';
  static const careerChapters = 'Bölüm';
  static const careerCollected = 'Toplam toplanan';
  static const careerVictims = 'Toplam mağdur';
  static const newCareer = 'Yeni kariyer';

  // Çıkış hamleleri
  static const exitOptions = 'Çıkış';
  static const sell = 'SAT';
  static const sellHint = 'Alıcı kasaya ve büyüklüğe bakar. Para temiz, iz az.';
  static const sellLocked =
      'Şu an alıcı yok. Defterlerin toparlanması ve ortalığın sakinleşmesi lazım.';
  static const sellValue = 'Teklif';
  static const handOver = 'DEVRET';
  static const handOverHint =
      'Kasayı bırakırsın, cebin kalır. Suç devralanda görünür, ama o da konuşabilir.';
  static const handOverLocked = 'Devralacak kimse yok.';
  static const confirmSell = 'Sat';
  static const confirmHandOver = 'Devret';
  static const sellConfirmTitle = 'Firmayı satıyor musun?';
  static const handOverConfirmTitle = 'Firmayı devrediyor musun?';
}
