import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaat/core/content.dart';
import 'package:vaat/core/prefs.dart';
import 'package:vaat/core/save_store.dart';
import 'package:vaat/game/game_controller.dart';
import 'package:vaat/game/game_state.dart';
import 'package:vaat_sim/vaat_sim.dart';

/// Kayıt ve geri yükleme. Oyuncunun kaybedecek bir şeyi olmamalı.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameContent content;
  late Prefs prefs;
  late Directory dir;

  setUpAll(() async {
    content = await GameContent.load();
    SharedPreferences.setMockInitialValues({'flutter.onboarding_seen': true});
    prefs = Prefs(await SharedPreferences.getInstance());
  });

  setUp(() {
    GameController.weekStepDelay = Duration.zero;
    dir = Directory.systemTemp.createTempSync('vaat_save_test');
  });

  tearDown(() {
    GameController.weekStepDelay = const Duration(milliseconds: 120);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  ProviderContainer makeGame(SaveStore store, {(GameState, int)? restored}) {
    final c = ProviderContainer(overrides: [
      contentProvider.overrideWithValue(content),
      prefsProvider.overrideWithValue(prefs),
      saveStoreProvider.overrideWithValue(store),
      restoredGameProvider.overrideWithValue(restored),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('oynanan oyun diske yazılır ve aynen geri yüklenir', () async {
    final store = SaveStore(dir);
    final first = makeGame(store);
    final ctrl = first.read(gameControllerProvider.notifier);

    await ctrl.endWeek();
    await ctrl.endWeek();
    final before = first.read(gameControllerProvider);
    // Yazma beklenmiyor olarak tetikleniyor; diske inmesini bekleyelim.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(store.hasSave, isTrue);

    final data = await store.readCurrent();
    expect(data, isNotNull);
    final restored = GameState.fromJson(data!);

    expect(restored.scheme.week, before.scheme.week);
    expect(restored.scheme.cash, before.scheme.cash);
    expect(restored.scheme.suspicion, before.scheme.suspicion);
    expect(restored.schemeTypeId, before.schemeTypeId);
    expect(restored.phase, before.phase);
    expect(restored.headlines.length, before.headlines.length);
    expect(restored.marketHistory, before.marketHistory);
  });

  test('kayıttan açılan oyun o haftadan devam eder', () async {
    final store = SaveStore(dir);
    final first = makeGame(store);
    await first.read(gameControllerProvider.notifier).endWeek();
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final data = (await store.readCurrent())!;
    final second = makeGame(
      store,
      restored: (GameState.fromJson(data), (data['seed'] as num).toInt()),
    );
    final loaded = second.read(gameControllerProvider);
    expect(loaded.scheme.week, first.read(gameControllerProvider).scheme.week);

    // Devam edebilmeli.
    await second.read(gameControllerProvider.notifier).endWeek();
    expect(second.read(gameControllerProvider).scheme.week,
        greaterThan(loaded.scheme.week));
  });

  test('kariyer varlıkları kayıtta korunur', () async {
    final store = SaveStore(dir);
    final c = makeGame(store);
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.flee();
    final game = c.read(gameControllerProvider);
    ctrl.state = game.copyWith(career: game.career.copyWith(cleanMoney: 9000000));
    ctrl.buyBusiness('exchange');
    ctrl.hireContact('lawyer');
    ctrl.buyEscapePart('passport');
    ctrl.setPartner(PartnerKind.political);
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final restored = GameState.fromJson((await store.readCurrent())!);
    expect(restored.career.businesses, contains('exchange'));
    expect(restored.career.contacts, contains('lawyer'));
    expect(restored.career.escapeParts, contains('passport'));
    expect(restored.career.partner, PartnerKind.political);
    expect(restored.phase, GamePhase.between);
  });

  test('bozuk kayıt sessizce atılır', () async {
    final store = SaveStore(dir);
    File('${dir.path}/career.json').writeAsStringSync('{bu json değil');
    expect(await store.readCurrent(), isNull);
    expect(store.hasSave, isFalse);
  });

  test('eski sürüm kayıt yüklenmez', () async {
    final store = SaveStore(dir);
    File('${dir.path}/career.json')
        .writeAsStringSync('{"version": 0, "data": {}}');
    expect(await store.readCurrent(), isNull);
  });

  test('biten kariyer skor tablosuna yazılır, en yüksek başta', () async {
    final store = SaveStore(dir);
    await store.addScore({'score': 100.0, 'chapters': 1});
    await store.addScore({'score': 900.0, 'chapters': 3});
    await store.addScore({'score': 400.0, 'chapters': 2});

    final scores = await store.readScores();
    expect(scores, hasLength(3));
    expect(scores.first['score'], 900.0);
    expect(scores.last['score'], 100.0);
  });

  test('yeni kariyer eski kaydın üstüne yazar', () async {
    final store = SaveStore(dir);
    final c = makeGame(store);
    final ctrl = c.read(gameControllerProvider.notifier);
    await ctrl.endWeek();
    await Future<void>.delayed(const Duration(milliseconds: 80));

    ctrl.newCareer();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final restored = GameState.fromJson((await store.readCurrent())!);
    expect(restored.scheme.week, 0);
    expect(restored.career.chapters, isEmpty);
  });
}
