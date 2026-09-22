import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';


import 'core/content.dart';
import 'core/prefs.dart';
import 'core/save_store.dart';
import 'game/game_controller.dart';
import 'game/game_state.dart';
import 'core/strings.dart';
import 'core/theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/game_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // İçerik ilk kareden önce yüklenir; iki küçük JSON, gecikme hissedilmez.
  final content = await GameContent.load();
  final prefs = Prefs(await SharedPreferences.getInstance());
  final store = await SaveStore.open();
  final restored = await _restore(store);

  runApp(
    ProviderScope(
      overrides: [
        contentProvider.overrideWithValue(content),
        prefsProvider.overrideWithValue(prefs),
        saveStoreProvider.overrideWithValue(store),
        restoredGameProvider.overrideWithValue(restored),
      ],
      child: const VaatApp(),
    ),
  );
}

/// Kaydı okur. Bozuk kayıt oyunu açılışta patlatmasın: hata olursa kayıt
/// atılır ve yeni kariyer başlar.
Future<(GameState, int)?> _restore(SaveStore store) async {
  final data = await store.readCurrent();
  if (data == null) return null;
  try {
    return (GameState.fromJson(data), (data['seed'] as num?)?.toInt() ?? 0);
  } catch (_) {
    await store.clearCurrent();
    return null;
  }
}

class VaatApp extends ConsumerWidget {
  const VaatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showOnboarding = ref.watch(onboardingVisibleProvider);
    return MaterialApp(
      title: Tr.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Öğretici oyunun üstüne biner; kapanınca arkadaki oyun hazır.
      home: showOnboarding ? const OnboardingScreen() : const GameShell(),
    );
  }
}
