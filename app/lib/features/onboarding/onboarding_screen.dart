import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/prefs.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../ui/pixel.dart';

/// İlk açılış öğreticisi. Dört anlatım sayfası ve iki sözlük sayfası: ne bu,
/// amaç ne, hangi iki sayıya bakılır, hiciv uyarısı, sonra ekrandaki her
/// sayının ne demek olduğu.
///
/// Neden ayrı ekran değil de kabuğun üstünde: oyuncu "Geç" deyince arkada
/// oyun hazır bekliyor, ikinci yükleme yok.
///
/// Sözlük sayfaları öğreticinin parçası ama asıl işi sonra başlıyor: ofisteki
/// "Nasıl oynanır?" bu ekranı yeniden açar, oyuncu bir sayının anlamını
/// unuttuğunda buraya döner. Ayrı bir sözlük ekranı bu yüzden yok.
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

  /// Anlatım sayfaları + iki sözlük sayfası.
  int get _pageCount => Tr.onboardingPages.length + 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final story = Tr.onboardingPages;
    final last = _page == _pageCount - 1;

    return Scaffold(
      backgroundColor: Px.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
              // Ad ve alt başlık alt alta: dar telefonlarda tek satıra
              // sığmıyor ve kırpılmış bir oyun adı kötü duruyor.
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Tr.appTitle.toUpperCase(),
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: AppSizes.displayBase * 1.5,
                            height: 1,
                            color: Px.gold,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(Tr.appSubtitle, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (!last)
                    PixelButton(
                      label: Tr.onboardingSkip,
                      kind: PixelButtonKind.ghost,
                      dense: true,
                      expand: false,
                      onPressed: _finish,
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pageCount,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  if (i < story.length) {
                    final (title, body) = story[i];
                    return _StoryPage(
                      index: i,
                      count: _pageCount,
                      title: title,
                      body: body,
                    );
                  }
                  final terms =
                      i == story.length ? Tr.glossaryPageA : Tr.glossaryPageB;
                  return _GlossaryPage(
                    index: i,
                    count: _pageCount,
                    terms: terms,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  // Kare pixel ilerleme noktaları.
                  for (var i = 0; i < _pageCount; i++)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: i == _page
                          ? const BoxDecoration(color: Px.gold)
                          : pixelBevel(
                              fill: Px.inset, raised: false, width: 2),
                    ),
                  const Spacer(),
                  PixelButton(
                    label: last ? Tr.onboardingStart : Tr.onboardingNext,
                    kind: PixelButtonKind.primary,
                    icon: last ? Icons.play_arrow_rounded : null,
                    expand: false,
                    onPressed: last
                        ? _finish
                        : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                            ),
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

/// Anlatım sayfası: numara, büyük başlık, gövde. Panel içinde.
class _StoryPage extends StatelessWidget {
  const _StoryPage({
    required this.index,
    required this.count,
    required this.title,
    required this.body,
  });

  final int index;
  final int count;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PixelPanel(
            title: '${index + 1} / $count',
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.displaySmall),
                const SizedBox(height: 14),
                Text(body, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sözlük sayfası: her terim ikon, başlık ve bir iki cümle.
class _GlossaryPage extends StatelessWidget {
  const _GlossaryPage({
    required this.index,
    required this.count,
    required this.terms,
  });

  final int index;
  final int count;
  final List<(String, String, String)> terms;

  /// Sözlükteki ikonlar HUD'dakilerle aynı; oyuncu ekranda gördüğü işareti
  /// burada tanısın.
  static IconData _icon(String key) => switch (key) {
        'cash' => Icons.savings_outlined,
        'promised' => Icons.receipt_long_outlined,
        'hole' => Icons.warning_amber_rounded,
        'coverage' => Icons.shield_outlined,
        'suspicion' => Icons.visibility_outlined,
        'panic' => Icons.local_fire_department_outlined,
        'investors' => Icons.groups_outlined,
        'rate' => Icons.percent_rounded,
        'skim' => Icons.account_balance_wallet_outlined,
        'inflow' => Icons.campaign_outlined,
        'record' => Icons.folder_outlined,
        _ => Icons.help_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Panel içeriğine sarılır, uzun telefonda altında boşluk kalır; kısa
    // telefonda ise sayfa kayar. ListView burada paneli ekranın dibine
    // kadar uzatıyordu.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: PixelPanel(
        title: '${Tr.glossaryTitle} · ${index + 1} / $count',
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (key, title, body) in terms)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                decoration:
                    pixelBevel(fill: Px.inset, raised: false, width: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_icon(key), size: 18, color: Px.gold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.toUpperCase(),
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: AppSizes.displayBase,
                              height: 1,
                              color: Px.text,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(body, style: theme.textTheme.bodySmall),
                        ],
                      ),
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
