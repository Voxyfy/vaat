import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../core/content.dart';
import '../core/save_store.dart';
import 'game_state.dart';

/// Oyunun tek kumandası. Simülasyonu çağıran tek yer burası.
class GameController extends Notifier<GameState> {
  late SimRng _rng;

  /// Bir "Hafta kapat" basışında en fazla kaç hafta akar. Neden: olaysız
  /// haftalar sıkıcı, ama sınırsız akış oyuncuyu bir yılı kaçırmış gibi
  /// hissettirir. Kart düşerse veya şema biterse daha erken durur.
  static const maxWeeksPerPress = 8;

  /// Bölüm sonunda önüne konan şema teklifi sayısı.
  static const offerCount = 3;

  /// Otomatik akan haftalar arasındaki bekleme. Sayılar tek karede zıplamasın
  /// diye var. Testler sıfırlar: gerçek bekleme, yüzlerce haftayı koşturan
  /// testleri dakikalarca yavaşlatıyor.
  @visibleForTesting
  static Duration weekStepDelay = const Duration(milliseconds: 120);

  GameContent get _content => ref.read(contentProvider);

  /// Kariyerin bölüm içine taşıdığı çarpanlar. İşletmeler, tanıdıklar ve
  /// ortak her hafta etkisini gösterir.
  CareerModifiers _modifiers() {
    final c = state.career;
    final biz = _content.businesses;
    final contacts = _content.contacts;
    final partner = c.partner;
    return CareerModifiers(
      suspicionShield: c.suspicionShield(biz, contacts) *
          (partner?.suspicionFactor ?? 1.0),
      channelBonus: c.channelBonus(biz) * (partner?.channelFactor ?? 1.0),
      weeklyIncome: c.weeklyBusinessIncome(biz),
      launderPerWeek: c.launderCapacity(biz),
      partnerCut: partner?.profitCut ?? 0,
    );
  }

  SaveStore get _store => ref.read(saveStoreProvider);

  @override
  GameState build() {
    // Kayıt main() içinde okunup buraya veriliyor; ilk kare çizilmeden önce
    // hazır olsun ki oyuncu bir an "yeni oyun" ekranı görüp sonra kaydına
    // atlamasın.
    final restored = ref.read(restoredGameProvider);
    if (restored != null) {
      _rng = SimRng(restored.$2);
      _seed = restored.$2;
      return restored.$1;
    }
    return _newCareer(seed: DateTime.now().millisecondsSinceEpoch);
  }

  int _seed = 0;

  /// Oyunu diske yazar. Her hafta sonunda ve her faz değişiminde çağrılır;
  /// oyuncu uygulamayı kapattığında kaybedecek bir şeyi olmasın.
  void _save() {
    final snapshot = {...state.toJson(), 'seed': _seed};
    // Beklenmiyor ve hatası yutuluyor: disk dolu veya dizin yoksa oyun
    // durmamalı, yalnız o anki kayıt atlanmalı.
    unawaited(_store.writeCurrent(snapshot).catchError((Object _) {}));
  }

  // --- Kariyer ---

  GameState _newCareer({required int seed}) {
    _rng = SimRng(seed);
    _seed = seed;
    const career = CareerState.fresh();
    final first = _content.scheme('classicPonzi');
    final scheme = _startScheme(first, career);
    return GameState(
      career: career,
      scheme: scheme,
      schemeTypeId: first.id,
      phase: GamePhase.running,
      draftRate: scheme.promisedRateWeekly,
      draftSkim: scheme.skim,
      queued: const [],
      answers: const {},
      headlines: const [],
      cashHistory: [scheme.cash],
      promisedHistory: [scheme.promisedTotal],
      marketHistory: [scheme.market.index],
      offers: const [],
      busy: false,
    );
  }

  void newCareer() {
    state = _newCareer(seed: DateTime.now().millisecondsSinceEpoch);
    _save();
  }

  /// Yeni şemayı kariyerin birikimiyle kurar: sermaye taşınır, geçmiş dosyası
  /// başlangıç şüphesi olur.
  SchemeState _startScheme(SchemeType type, CareerState career) {
    final cfg = _content.balance;
    // İlk bölümde tür kendi sermayesini getirir; sonrakilerde oyuncunun
    // taşıdığı para sermayedir, ama türün kurulum maliyetinin altına düşemez.
    final own = career.chapters.isEmpty
        ? type.startCash
        : math.max(career.usableCapital, type.startCash * 0.25);
    // Ortak sermaye koyar; karşılığını kârdan alır.
    final capital = own * (1 + (career.partner?.capitalShare ?? 0));
    return SchemeState.initial(
      type: type,
      cash: capital,
      seedInvestors: 10,
      seedTicket: cfg.segments[type.seedSegment]!.ticket,
      skim: 0.13,
      startingSuspicion: career.record * 0.6,
    );
  }

  /// Bölümü kapat, kariyere yaz, "aradaki hayat" ekranına geç.
  void _closeChapter() {
    final type = _content.scheme(state.schemeTypeId);
    final career = closeChapter(
      career: state.career,
      scheme: state.scheme,
      type: type,
      escapeReadiness: state.career
          .escapeReadiness(_content.escapeParts, _content.contacts),
    );
    state = state.copyWith(
      career: career,
      phase: career.over ? GamePhase.careerOver : GamePhase.between,
      offers: career.over ? const [] : _rollOffers(career),
      busy: false,
    );
    if (career.over) {
      unawaited(_store.addScore({
        'score': career.score,
        'chapters': career.chapters.length,
        'weeks': career.chapters.fold(0, (sum, c) => sum + c.weeks),
        'collected':
            career.chapters.fold(0.0, (sum, c) => sum + c.collected),
        'victims': career.chapters.fold(0, (sum, c) => sum + c.victims),
        'endedAt': DateTime.now().toIso8601String(),
        'lastScheme': career.chapters.last.schemeName,
      }).catchError((Object _) {}));
    }
    _save();
  }

  /// Sonraki bölümde önüne konan şemalar. Aynı türü üst üste oynamak sıkıcı,
  /// ama hepsini elemek de seçeneksiz bırakır: son oynanan hariç rastgele.
  List<String> _rollOffers(CareerState career) {
    final last = career.playedSchemeIds.isEmpty
        ? null
        : career.playedSchemeIds.last;
    // İşletmelerin kilidini açtığı türler dışında, kilit isteyen şemalar
    // teklif havuzuna girmez.
    final unlocked = career.unlockedSchemes(_content.businesses);
    final pool = [
      for (final t in _content.schemes)
        if (t.id != last &&
            (t.requires.isEmpty || unlocked.containsAll(t.requires)))
          t.id,
    ]..shuffle(_random);
    return pool.take(math.min(offerCount, pool.length)).toList();
  }

  /// Şema seçimi oyuncunun kararı, simülasyonun değil; ayrı bir rastgelelik
  /// kaynağı kullanıyoruz ki run'ın determinizmi bozulmasın.
  final _random = math.Random();

  /// Gerçek iş satın al. Temiz paradan ödenir: kara parayla açıkça şirket
  /// almak zaten şüphe çeker.
  bool buyBusiness(String id) {
    if (state.phase != GamePhase.between) return false;
    final b = _content.business(id);
    final c = state.career;
    if (c.businesses.contains(id) || c.cleanMoney < b.price) return false;
    state = state.copyWith(
      career: c.copyWith(
        cleanMoney: c.cleanMoney - b.price,
        businesses: [...c.businesses, id],
      ),
      offers: _rollOffers(c),
    );
    _save();
    return true;
  }

  /// Ağa birini kat.
  bool hireContact(String id) {
    if (state.phase != GamePhase.between) return false;
    final t = _content.contact(id);
    final c = state.career;
    if (c.contacts.contains(id) || c.cleanMoney < t.price) return false;
    state = state.copyWith(
      career: c.copyWith(
        cleanMoney: c.cleanMoney - t.price,
        contacts: [...c.contacts, id],
      ),
    );
    _save();
    return true;
  }

  /// Kaçış planına bir parça ekle.
  bool buyEscapePart(String id) {
    if (state.phase != GamePhase.between) return false;
    final p = _content.escapePart(id);
    final c = state.career;
    if (c.escapeParts.contains(id) || c.cleanMoney < p.price) return false;
    state = state.copyWith(
      career: c.copyWith(
        cleanMoney: c.cleanMoney - p.price,
        escapeParts: [...c.escapeParts, id],
      ),
    );
    _save();
    return true;
  }

  /// Sonraki bölüme ortak al veya vazgeç.
  void setPartner(PartnerKind? kind) {
    if (state.phase != GamePhase.between) return;
    state = state.copyWith(
      career: kind == null
          ? state.career.copyWith(clearPartner: true)
          : state.career.copyWith(partner: kind),
    );
    _save();
  }

  void chooseScheme(String typeId) {
    if (state.phase != GamePhase.between) return;
    final type = _content.scheme(typeId);
    final scheme = _startScheme(type, state.career);
    state = state.copyWith(
      scheme: scheme,
      schemeTypeId: type.id,
      phase: GamePhase.running,
      draftRate: scheme.promisedRateWeekly,
      draftSkim: scheme.skim,
      queued: const [],
      answers: const {},
      headlines: const [],
      cashHistory: [scheme.cash],
      promisedHistory: [scheme.promisedTotal],
      marketHistory: [scheme.market.index],
      offers: const [],
      busy: false,
    );
    _save();
  }

  // --- Şema içi hamleler ---

  void setDraftRate(double weekly) => state = state.copyWith(draftRate: weekly);

  void setDraftSkim(double skim) => state = state.copyWith(draftSkim: skim);

  void answerEvent(String eventId, int optionIndex) {
    final queued = [
      for (final a in state.queued)
        if (!(a is ResolveEvent && a.eventId == eventId)) a,
      ResolveEvent(eventId, optionIndex),
    ];
    state = state.copyWith(
      queued: queued,
      answers: {...state.answers, eventId: optionIndex},
    );
  }

  void queue(PlayerAction action) =>
      state = state.copyWith(queued: [...state.queued, action]);

  /// Çıkış hamleleri hafta kapatmaz; tek başına gider ve bölümü kapatır.
  void flee() => _exit(const Flee());

  void sell() => _exit(const SellScheme());

  void handOver() => _exit(const HandOverScheme());

  void _exit(PlayerAction action) {
    if (state.phase != GamePhase.running || state.scheme.isOver) return;
    _advance([action]);
    if (state.scheme.isOver) _closeChapter();
  }

  /// Haftayı kapat. Kaydıraç taslakları hamleye dönüşür, kuyruk boşalır,
  /// sonra olay düşene veya şema bitene kadar haftalar akar.
  Future<void> endWeek() async {
    if (state.busy || state.phase != GamePhase.running || state.scheme.isOver) {
      return;
    }
    final actions = <PlayerAction>[...state.queued];
    if (state.draftRate != state.scheme.promisedRateWeekly) {
      actions.add(SetPromisedRate(state.draftRate));
    }
    if (state.draftSkim != state.scheme.skim) {
      actions.add(SetSkim(state.draftSkim));
    }
    state = state.copyWith(busy: true, queued: const [], answers: const {});
    for (var i = 0; i < maxWeeksPerPress; i++) {
      final stop = _advance(i == 0 ? actions : const []);
      if (stop) break;
      if (weekStepDelay > Duration.zero) {
        await Future<void>.delayed(weekStepDelay);
      }
    }
    if (state.scheme.isOver) {
      _closeChapter();
    } else {
      state = state.copyWith(busy: false);
      _save();
    }
  }

  /// Bir hafta ilerletir. Durma gerekiyorsa (olay, bitiş) true döner.
  bool _advance(List<PlayerAction> actions) {
    final type = _content.scheme(state.schemeTypeId);
    final result = tick(
      state.scheme,
      actions,
      _rng,
      _content.balance,
      _content.events,
      type,
      career: _modifiers(),
    );
    final s = result.state;
    // Aklama hafta hafta akıyor: işletmelerin kapasitesi kadar kara para
    // temize geçiyor. Tek seferde aklamak yok, sabır gerekiyor.
    var career = state.career;
    if (result.laundered > 0 && career.dirtyMoney > 0) {
      final moved = math.min(result.laundered, career.dirtyMoney);
      career = career.copyWith(
        dirtyMoney: career.dirtyMoney - moved,
        cleanMoney: career.cleanMoney + moved,
      );
    }
    final headlines = [
      ...state.headlines,
      for (final line in result.log) Headline(s.week, line),
    ];
    state = state.copyWith(
      career: career,
      scheme: s,
      draftRate: s.promisedRateWeekly,
      draftSkim: s.skim,
      headlines: headlines,
      cashHistory: [...state.cashHistory, s.cash],
      promisedHistory: [...state.promisedHistory, s.promisedTotal],
      marketHistory: [...state.marketHistory, s.market.index],
    );
    return s.isOver || result.newEvents.isNotEmpty;
  }
}

/// Açılışta diskten okunan oyun. main() içinde override edilir; kayıt yoksa
/// null kalır ve yeni kariyer başlar. İkinci değer RNG tohumu: aynı kayıttan
/// devam eden oyun aynı rastgele diziyi sürdürsün.
final restoredGameProvider = Provider<(GameState, int)?>((_) => null);

final gameControllerProvider =
    NotifierProvider<GameController, GameState>(GameController.new);
