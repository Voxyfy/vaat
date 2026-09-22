import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/prefs.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';

/// İlk açılış öğreticisi. Dört sayfa: ne bu, amaç ne, hangi iki sayıya
/// bakılır, hiciv uyarısı. Neden ayrı ekran değil de kabuğun üstünde:
/// oyuncu "Geç" deyince arkada oyun hazır bekliyor, ikinci yükleme yok.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  var _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => ref.read(onboardingVisibleProvider.notifier).dismiss();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = Tr.onboardingPages;
    final last = _page == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
              // Ad ve alt baslik alt alta: dar telefonlarda tek satira
              // sigmiyor ve kirpilmis bir oyun adi kotu duruyor.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(Tr.appTitle.toUpperCase(),
                          style: theme.textTheme.headlineSmall),
                      const Spacer(),
                      if (!last)
                        TextButton(
                            onPressed: _finish,
                            child: const Text(Tr.onboardingSkip)),
                    ],
                  ),
                  Text(Tr.appSubtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final (title, body) = pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}/${pages.length}',
                            style: monoStyle(context,
                                color: theme.colorScheme.primary)),
                        const SizedBox(height: 12),
                        Text(title, style: theme.textTheme.displaySmall),
                        const SizedBox(height: 20),
                        Text(body, style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  for (var i = 0; i < pages.length; i++)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 6),
                      color: i == _page
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: last
                        ? _finish
                        : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                            ),
                    child: Text(last ? Tr.onboardingStart : Tr.onboardingNext),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
