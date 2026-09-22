import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaat/core/content.dart';
import 'package:vaat/core/prefs.dart';
import 'package:vaat/core/save_store.dart';
import 'package:vaat/core/theme.dart';
import 'package:vaat/features/hud/hud_bar.dart';
import 'package:vaat/features/market/market_tab.dart';
import 'package:vaat/features/media/media_tab.dart';
import 'package:vaat/features/office/office_tab.dart';
import 'package:vaat/features/pool/pool_tab.dart';
import 'package:vaat/features/protection/protection_tab.dart';
import 'package:vaat/game/game_controller.dart';

/// Her sekmeyi tek basina telefon genisliginde yerlestirir. IndexedStack
/// hepsini ayni anda yerlestirdigi icin toplu testte tasmanin hangi sekmeden
/// geldigi anlasilmiyordu.
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

  setUp(() => GameController.weekStepDelay = Duration.zero);
  tearDown(
      () => GameController.weekStepDelay = const Duration(milliseconds: 120));

  final screens = <String, Widget>{
    'HUD': const HudBar(),
    'Ofis': const OfficeTab(),
    'Havuz': const PoolTab(),
    'Piyasa': const MarketTab(),
    'Medya': const MediaTab(),
    'Koruma': const ProtectionTab(),
  };

  /// Borsa tahtası yalnız hisse oynatılan şemada görünür; piyasa sekmesini
  /// bir de o şemayla denemek gerekiyor.
  testWidgets('Piyasa sekmesi borsa şemasında taşmıyor', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      contentProvider.overrideWithValue(content),
      prefsProvider.overrideWithValue(prefs),
      saveStoreProvider.overrideWithValue(SaveStore(tempDir)),
    ]);
    addTearDown(container.dispose);
    final ctrl = container.read(gameControllerProvider.notifier);
    ctrl.flee();
    ctrl.chooseScheme('stockManipulation');
    await ctrl.endWeek();
    expect(container.read(gameControllerProvider).scheme.board.isActive, isTrue);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: SafeArea(child: MarketTab())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final entry in screens.entries) {
    testWidgets('${entry.key} telefon genişliğinde taşmıyor', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(overrides: [
        contentProvider.overrideWithValue(content),
        prefsProvider.overrideWithValue(prefs),
        saveStoreProvider.overrideWithValue(SaveStore(tempDir)),
      ]);
      addTearDown(container.dispose);
      // Birkaç hafta oynansın ki rakamlar büyüsün; dar ekranı asıl zorlayan
      // "1.25 mn TL" gibi uzun değerler.
      await container.read(gameControllerProvider.notifier).endWeek();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildTheme(),
            home: Scaffold(body: SafeArea(child: entry.value)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
