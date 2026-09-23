import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaat/core/content.dart';
import 'package:vaat/core/prefs.dart';
import 'package:vaat/core/save_store.dart';
import 'package:vaat/core/strings.dart';
import 'package:vaat/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Testler gerçek kayıt dizinine yazmasın; her dosya kendi geçici klasörünü
  /// kullanır ve sonunda siler.
  late Directory tempDir;
  setUp(() => tempDir = Directory.systemTemp.createTempSync('vaat_test'));
  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Testler varsayilan 800x600 ile kosar; bu telefon degil ve dar ekranda
  /// tasan yerlesimleri gizler. Gercek hedef cihaz genisligine sabitliyoruz:
  /// tasma olursa Flutter hata firlatir ve test kirmizi olur.
  void usePhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('içerik yüklenir, haftalar kapanır, sekmeler açılır',
      (tester) async {
    usePhoneSize(tester);
    final content = await GameContent.load();
    expect(content.balance.segments, isNotEmpty);
    expect(content.events.defs, isNotEmpty);

    SharedPreferences.setMockInitialValues({});
    final prefs = Prefs(await SharedPreferences.getInstance());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentProvider.overrideWithValue(content),
          prefsProvider.overrideWithValue(prefs),
        saveStoreProvider.overrideWithValue(SaveStore(tempDir)),
        ],
        child: const VaatApp(),
      ),
    );
    await tester.pumpAndSettle();

    // İlk açılış: öğretici görünür, "Geç" oyunu açar ve bayrağı yazar.
    expect(find.text(Tr.onboardingSkip), findsOneWidget);
    await tester.tap(find.text(Tr.onboardingSkip));
    await tester.pumpAndSettle();
    expect(prefs.onboardingSeen, isTrue);

    // HUD sayacı "HAFTA 0" biçiminde tek metin.
    String week() =>
        (tester.widget<Text>(find.byKey(const Key('hud-week')))).data!;
    expect(week(), endsWith(' 0'));

    // Üç kez hafta kapat: sayaç ilerlemeli, hata fırlamamalı.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text(Tr.endWeek));
      await tester.pump();
      // Otomatik akış 8 haftaya kadar 120 ms bekler.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }
    expect(week(), isNot(endsWith(' 0')));

    for (final label in [Tr.tabPool, Tr.tabMarket, Tr.tabMedia, Tr.tabProtection]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$label sekmesi taştı');
    }
    // Kaç düğmesi listenin altında olabilir; kaydırarak bul.
    await tester.scrollUntilVisible(find.text(Tr.flee), 200,
        scrollable: find.byType(Scrollable).last);
    expect(find.text(Tr.flee), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
