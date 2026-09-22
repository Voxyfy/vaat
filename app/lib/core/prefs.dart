import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Küçük kalıcı bayraklar. Oyun kaydı Drift'e gidecek, buraya yalnız
/// "öğretici görüldü" gibi tek bitlik şeyler girer.
class Prefs {
  Prefs(this._sp);

  final SharedPreferences _sp;

  static const _onboardingSeen = 'onboarding_seen';

  bool get onboardingSeen => _sp.getBool(_onboardingSeen) ?? false;

  Future<void> markOnboardingSeen() => _sp.setBool(_onboardingSeen, true);
}

/// main() içinde override edilir.
final prefsProvider = Provider<Prefs>(
  (_) => throw UnimplementedError('prefsProvider main() içinde override edilmeli'),
);

/// Öğretici gösterilsin mi. Uygulama açılışında prefs'ten okunur, oyuncu
/// "Nasıl oynanır?" deyince yeniden true olur.
class OnboardingVisible extends Notifier<bool> {
  @override
  bool build() => !ref.read(prefsProvider).onboardingSeen;

  void show() => state = true;

  Future<void> dismiss() async {
    state = false;
    await ref.read(prefsProvider).markOnboardingSeen();
  }
}

final onboardingVisibleProvider =
    NotifierProvider<OnboardingVisible, bool>(OnboardingVisible.new);
