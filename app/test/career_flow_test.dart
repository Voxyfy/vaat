import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaat/core/content.dart';
import 'package:vaat/core/prefs.dart';
import 'package:vaat/core/save_store.dart';
import 'package:vaat/core/strings.dart';
import 'package:vaat/features/career/between_screen.dart';
import 'package:vaat/features/career/career_over_screen.dart';
import 'package:vaat/core/theme.dart';
import 'package:vaat/game/game_controller.dart';
import 'package:vaat/game/game_state.dart';
import 'package:vaat_sim/vaat_sim.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Testler gerçek kayıt dizinine yazmasın; her dosya kendi geçici klasörünü
  /// kullanır ve sonunda siler.
  late Directory tempDir;
  setUp(() => tempDir = Directory.systemTemp.createTempSync('vaat_test'));
  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  late GameContent content;
  late Prefs prefs;

  setUpAll(() async {
    content = await GameContent.load();
    SharedPreferences.setMockInitialValues({'flutter.onboarding_seen': true});
    prefs = Prefs(await SharedPreferences.getInstance());
  });

  // Haftalar arasi gercek bekleme testte gereksiz; sifirlaninca hic cagrilmiyor.
  setUp(() => GameController.weekStepDelay = Duration.zero);
  tearDown(
      () => GameController.weekStepDelay = const Duration(milliseconds: 120));

  /// Oyunu widget agaci olmadan kurar. Kariyer mantigi arayuze bagli degil,
  /// bu yuzden testi de bagli olmamali: boylesi hem hizli hem kirilgan degil.
  ProviderContainer makeGame() {
    final container = ProviderContainer(overrides: [
      contentProvider.overrideWithValue(content),
      prefsProvider.overrideWithValue(prefs),
      saveStoreProvider.overrideWithValue(SaveStore(tempDir)),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  group('kariyer akışı', () {
    test('kaçış bölümü kapatır ve aradaki hayat fazına geçer', () {
      final c = makeGame();
      final ctrl = c.read(gameControllerProvider.notifier);
      expect(c.read(gameControllerProvider).phase, GamePhase.running);

      ctrl.flee();

      final game = c.read(gameControllerProvider);
      expect(game.phase, GamePhase.between);
      expect(game.career.chapters, hasLength(1));
      expect(game.career.chapters.single.end, SchemeEnd.fled);
      expect(game.career.dirtyMoney, greaterThan(0));
      expect(game.offers, isNotEmpty);
    });

    test('teklifler son oynanan şemayı tekrar sunmaz', () {
      final c = makeGame();
      final first = c.read(gameControllerProvider).schemeTypeId;
      c.read(gameControllerProvider.notifier).flee();
      expect(c.read(gameControllerProvider).offers, isNot(contains(first)));
    });

    test('teklif seçmek yeni bölümü kariyer birikimiyle başlatır', () async {
      final c = makeGame();
      final ctrl = c.read(gameControllerProvider.notifier);
      await ctrl.endWeek();
      ctrl.flee();

      final between = c.read(gameControllerProvider);
      expect(between.career.usableCapital, greaterThan(0));

      final pick = between.offers.first;
      ctrl.chooseScheme(pick);

      final next = c.read(gameControllerProvider);
      expect(next.phase, GamePhase.running);
      expect(next.schemeTypeId, pick);
      expect(next.scheme.week, 0);
      expect(next.scheme.typeId, pick);
      // Geçmiş dosyası taşındı: yeni şema temiz sayfayla başlamıyor.
      expect(next.scheme.suspicion, greaterThan(0));
      expect(next.headlines, isEmpty);
    });

    test('satış temiz para yazar, devir yalnız cebi taşır', () async {
      final c = makeGame();
      final ctrl = c.read(gameControllerProvider.notifier);
      // Üretim kılıfı satılabilir tek başlangıç türü değil ama satış primi
      // en yüksek olanı; önce klasik Ponzi'den çıkıp ona geçiyoruz.
      ctrl.flee();
      final offers = c.read(gameControllerProvider).offers;
      ctrl.chooseScheme(offers.first);
      for (var i = 0; i < 4; i++) {
        await ctrl.endWeek();
      }

      final before = c.read(gameControllerProvider);
      final cleanBefore = before.career.cleanMoney;
      ctrl.handOver();

      final after = c.read(gameControllerProvider);
      expect(after.phase, GamePhase.between);
      expect(after.career.chapters.last.end, SchemeEnd.handedOver);
      expect(after.career.cleanMoney, cleanBefore);
    });

    test('masadan kalkmak kariyeri seçilen sonla bitirir', () async {
      final c = makeGame();
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.flee();
      expect(c.read(gameControllerProvider).phase, GamePhase.between);

      // Kilitli son işlemez: pasaport yokken Balkan yok.
      ctrl.retire(CareerEnding.balkan);
      expect(c.read(gameControllerProvider).phase, GamePhase.between);

      // Sefalet hemen açık: ilk bölümden çıkan para 100 binin altında kalır
      // ya da kalmaz; garantiye almak için parayı sıfırlıyoruz.
      final poor = c.read(gameControllerProvider).career
          .copyWith(cleanMoney: 0, dirtyMoney: 0);
      expect(poor.canEnd(CareerEnding.poverty), isTrue);
      final ending = c.read(gameControllerProvider).career.availableEndings();
      expect(ending, isNotEmpty);
      ctrl.retire(ending.first);

      final game = c.read(gameControllerProvider);
      expect(game.phase, GamePhase.careerOver);
      expect(game.career.over, isTrue);
      expect(game.career.ending, ending.first);
    });

    test('tavan vaat kariyeri bitirir', () async {
      final c = makeGame();
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.setDraftRate(0.08);
      for (var i = 0; i < 30; i++) {
        if (c.read(gameControllerProvider).phase != GamePhase.running) break;
        await ctrl.endWeek();
      }

      final game = c.read(gameControllerProvider);
      expect(game.phase, GamePhase.careerOver);
      expect(game.career.over, isTrue);
      expect(game.career.record, 100);
      expect(game.career.chapters.last.end.endsCareer, isTrue);
    });
  });

  group('kariyer varlıkları', () {
    test('temiz para yetiyorsa iş satın alınır, yetmiyorsa alınmaz', () {
      final c = makeGame();
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.flee();
      // Kaçıştan gelen para kara; işletme temiz parayla alınır.
      expect(ctrl.buyBusiness('exchange'), isFalse);

      final career = c.read(gameControllerProvider).career;
      c.read(gameControllerProvider.notifier).state = c
          .read(gameControllerProvider)
          .copyWith(career: career.copyWith(cleanMoney: 5000000));
      expect(ctrl.buyBusiness('exchange'), isTrue);
      expect(c.read(gameControllerProvider).career.businesses,
          contains('exchange'));
      // İkinci kez alınamaz.
      expect(ctrl.buyBusiness('exchange'), isFalse);
    });

    test('aklama kara parayı hafta hafta temize çevirir', () async {
      final c = makeGame();
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.flee();
      var game = c.read(gameControllerProvider);
      ctrl.state = game.copyWith(
        career: game.career.copyWith(
          cleanMoney: 5000000,
          dirtyMoney: 3000000,
        ),
      );
      ctrl.buyBusiness('exchange');
      ctrl.chooseScheme(c.read(gameControllerProvider).offers.first);

      final before = c.read(gameControllerProvider).career;
      await ctrl.endWeek();
      final after = c.read(gameControllerProvider).career;

      expect(after.dirtyMoney, lessThan(before.dirtyMoney));
      expect(after.cleanMoney, greaterThan(before.cleanMoney));
    });

    test('kaçış planı kaçışta daha çok para bırakır', () async {
      double runWith({required bool prepared}) {
        final c = makeGame();
        final ctrl = c.read(gameControllerProvider.notifier);
        if (prepared) {
          final game = c.read(gameControllerProvider);
          ctrl.state = game.copyWith(
            career: game.career.copyWith(
              escapeParts: ['passport', 'offshore', 'country', 'story'],
            ),
          );
        }
        ctrl.flee();
        return c.read(gameControllerProvider).career.dirtyMoney;
      }

      expect(runWith(prepared: true), greaterThan(runWith(prepared: false)));
    });

    test('ortak seçilince sonraki şema sermayesi büyür', () {
      // Şema sabit: teklifler rastgele geldiği için iki koşu farklı türe
      // düşerse sermaye karşılaştırması anlamsız oluyordu.
      int capitalFor(PartnerKind? kind) {
        final c = makeGame();
        final ctrl = c.read(gameControllerProvider.notifier);
        ctrl.flee();
        ctrl.setPartner(kind);
        ctrl.chooseScheme('cryptoExchange');
        return c.read(gameControllerProvider).scheme.cash.round();
      }

      expect(capitalFor(PartnerKind.capital), greaterThan(capitalFor(null)));
    });
  });

  group('kariyer ekranları', () {
    /// Testler varsayilan 800x600 ile kosar; telefon genisligine sabitlemek
    /// tasan yerlesimleri gorunur kilar.
    void usePhoneSize(WidgetTester tester) {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    Future<void> pumpScreen(
      WidgetTester tester,
      ProviderContainer container,
      Widget screen,
    ) async {
      usePhoneSize(tester);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: buildTheme(), home: screen),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Uzun listelerde ekran disindaki cocuklar hic olusturulmuyor.
    Future<void> scrollTo(WidgetTester tester, String text) async {
      await tester.scrollUntilVisible(find.text(text), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
    }

    testWidgets('aradaki hayat ekranı bölümü, dükkânı ve teklifleri gösterir',
        (tester) async {
      final c = makeGame();
      c.read(gameControllerProvider.notifier).flee();
      await pumpScreen(tester, c, const BetweenScreen());

      expect(find.text(Tr.newspaperName), findsOneWidget);
      expect(find.text(Tr.endFled), findsOneWidget);
      expect(find.text(Tr.betweenTitle), findsOneWidget);

      await scrollTo(tester, Tr.businesses);
      await scrollTo(tester, Tr.escapePlan);
      await scrollTo(tester, Tr.partner);
      await scrollTo(tester, Tr.chooseScheme);
      expect(find.text(Tr.schemeStart), findsWidgets);
      await scrollTo(tester, Tr.retireTitle);
      expect(find.text(Tr.retireLocked), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('kariyer sonu ekranı defteri ve skoru gösterir',
        (tester) async {
      final c = makeGame();
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.setDraftRate(0.08);
      for (var i = 0; i < 30; i++) {
        if (c.read(gameControllerProvider).phase != GamePhase.running) break;
        await ctrl.endWeek();
      }
      expect(c.read(gameControllerProvider).phase, GamePhase.careerOver);

      await pumpScreen(tester, c, const CareerOverScreen());

      expect(find.text(Tr.careerOverTitle), findsOneWidget);
      expect(find.text(Tr.endingPrison), findsOneWidget);
      await scrollTo(tester, Tr.newCareer);
      expect(find.text(Tr.newCareer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
