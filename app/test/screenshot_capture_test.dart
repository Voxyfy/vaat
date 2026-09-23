@Tags(['screenshots'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaat/core/content.dart';
import 'package:vaat/core/prefs.dart';
import 'package:vaat/core/save_store.dart';
import 'package:vaat/core/strings.dart';
import 'package:vaat/game/game_controller.dart';
import 'package:vaat/game/game_state.dart';
import 'package:vaat/game/office_game.dart';
import 'package:vaat/main.dart';

/// App Store ekran görüntülerini çeken düzenek. Ritim'deki aracın Vaat
/// sürümü.
///
/// Bu bir test değil, bir **çekim aracı**; doğrulama yapmaz, PNG üretir.
/// `test/` altında duruyor çünkü gerçek widget ağacını ancak `flutter test`
/// kurabiliyor; simülatörde programatik dokunma yok.
///
/// Normal koşuda kendini eler. Çalıştırmak için:
///
///     VAAT_SHOTS=1 flutter test test/screenshot_capture_test.dart --tags screenshots
///
/// Ardından alfa kanalını düşürmek için `python3 ../tools/flatten_screenshots.py`.
///
/// Ekranlar gerçek bir koşudan geliyor: sabit seed'le bir kariyer oynatılıyor,
/// kart düştüğü haftada duruluyor. Apple görüntülerin uygulamayı dürüst
/// temsil etmesini istiyor; burada kurgu yok, sadece seçilmiş bir an var.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Klasör adı App Store Connect yuvasının adı. 1290x2796 6.7" sınıfıdır,
  // 6.9" değil; yanlış yuvaya yükleme ölçü hatası veriyor.
  const devices = <_Device>[
    _Device(name: 'ios-6.9', logical: Size(440, 956), scale: 3), // 1320x2868
    _Device(name: 'ios-6.7', logical: Size(430, 932), scale: 3), // 1290x2796
    _Device(name: 'ios-6.5', logical: Size(414, 896), scale: 3), // 1242x2688
  ];

  late Directory tempDir;
  late GameContent content;
  late Prefs prefs;

  setUpAll(() async {
    await _loadRealFonts();
    // Flame'in kendi başlattığı yükleme sahte saat altında görsel çözümünde
    // takılıyor ve sahne boş çıkıyor. Görselleri burada gerçek zamanda,
    // ayrı bir örnekle önbelleğe alıyoruz; Flame'in görsel önbelleği ortak,
    // gerçek sahne yüklemeyi oradan anında tamamlıyor.
    await OfficeGame(background: const Color(0xFF000000)).onLoad();
    content = await GameContent.load();
    SharedPreferences.setMockInitialValues({'flutter.onboarding_seen': true});
    prefs = Prefs(await SharedPreferences.getInstance());
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('vaat_shots');
    GameController.weekStepDelay = Duration.zero;
  });
  tearDown(() {
    GameController.weekStepDelay = const Duration(milliseconds: 120);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  // Yalnız istenen cihazlar: VAAT_SHOT_DEVICES=ios-6.9 gibi.
  final only = Platform.environment['VAAT_SHOT_DEVICES']?.split(',');

  for (final device in devices) {
    testWidgets(
      '${device.name} ekran görüntüleri',
      skip: Platform.environment['VAAT_SHOTS'] != '1' ||
          (only != null && !only.contains(device.name)),
      (tester) async {
        final root = GlobalKey();
        tester.view.physicalSize = device.logical * device.scale.toDouble();
        tester.view.devicePixelRatio = device.scale.toDouble();
        // Çentik ve ana ekran çubuğu: gerçek cihazdaki güvenli alan.
        tester.view.padding = FakeViewPadding(
          top: 59 * device.scale.toDouble(),
          bottom: 34 * device.scale.toDouble(),
        );
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);

        final container = ProviderContainer(overrides: [
          contentProvider.overrideWithValue(content),
          prefsProvider.overrideWithValue(prefs),
          saveStoreProvider.overrideWithValue(SaveStore(tempDir)),
          // Sabit seed: her çekimde aynı haftalar, aynı kartlar.
          restoredGameProvider.overrideWithValue(null),
        ]);
        addTearDown(container.dispose);
        final ctrl = container.read(gameControllerProvider.notifier);

        await tester.pumpWidget(
          RepaintBoundary(
            key: root,
            child: UncontrolledProviderScope(
              container: container,
              child: const VaatApp(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        // Sekme ikonları da görsel dosyası; sahte saat altında yüklenmez ve
        // çubuk boş çıkar. Gerçek zamanda önbelleğe al.
        await tester.runAsync(() async {
          final ctx = tester.element(find.byType(VaatApp));
          for (final name in [
            'tab_office', 'tab_pool', 'tab_market', 'tab_media', 'tab_protection',
          ]) {
            await precacheImage(AssetImage('assets/icons/$name.png'), ctx);
          }
        });
        await tester.pump();

        Future<void> settle() async {
          // Flame sprite'ları gerçek zamanda yüklenir; sahte saat altında
          // hiç gelmez ve sahne boş çıkar. Önce gerçek zamanda bekle.
          // Flame sahnesi sürekli kare istiyor; pumpAndSettle burada
          // sonsuza kadar bekleyebilir. Birkaç sabit kare yeter.
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        Future<void> shot(String file) => _writePng(
              tester,
              root,
              '../screenshots/${device.name}/$file.png',
              device.scale.toDouble(),
            );

        Future<void> tab(String label) async {
          await tester.tap(find.text(label));
          await settle();
        }

        // Oyunu bir kart düşene kadar akıt; ofiste kart görünsün.
        for (var i = 0; i < 40; i++) {
          final g = container.read(gameControllerProvider);
          if (g.phase != GamePhase.running) break;
          if (g.scheme.pendingEventIds.isNotEmpty && g.scheme.week >= 6) break;
          await ctrl.endWeek();
        }
        await settle();
        await shot('01-ofis');

        await tab(Tr.tabPool);
        await shot('02-havuz');
        await tab(Tr.tabMarket);
        await shot('03-piyasa');
        await tab(Tr.tabMedia);
        await shot('04-medya');
        await tab(Tr.tabProtection);
        await shot('05-koruma');

        // Aradaki hayat: kaç, para say, sıradaki işi seç.
        ctrl.flee();
        await settle();
        await shot('06-aradaki-hayat');

        // Borsa şeması: piyasa sekmesi orada tamamen farklı.
        ctrl.chooseScheme('stockManipulation');
        await settle();
        for (var i = 0; i < 6; i++) {
          await ctrl.endWeek();
        }
        await settle();
        await tab(Tr.tabMarket);
        await shot('07-borsa');

        // Ağaç sökülmeden test bitmesin: Flame ticker'ı bekleyen
        // zamanlayıcı sayılır ve koşu kırmızı biter.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }
}

class _Device {
  const _Device({
    required this.name,
    required this.logical,
    required this.scale,
  });
  final String name;
  final Size logical;
  final int scale;
}

/// Ağacın o anki hâlini PNG olarak yazar. Golden karşılaştırıcısı 1x
/// yakalıyor; mağaza ölçüsü için piksel oranı elle veriliyor.
Future<void> _writePng(
  WidgetTester tester,
  GlobalKey root,
  String path,
  double scale,
) async {
  final boundary =
      root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: scale);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path)..parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

/// `flutter test` yalnız ölçüm amaçlı yer tutucu bir yazı tipi yüklüyor;
/// gerçek yazı tipleri yüklenmezse metinler siyah kutu çıkar.
Future<void> _loadRealFonts() async {
  final raw = await rootBundle.loadString('FontManifest.json');
  final families = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  for (final family in families) {
    final loader = FontLoader(family['family'] as String);
    for (final font in (family['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}
