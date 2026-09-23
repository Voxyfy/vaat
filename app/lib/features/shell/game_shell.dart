import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../game/game_controller.dart';
import '../../game/game_state.dart';
import '../../ui/pixel.dart';
import '../hud/hud_bar.dart';
import '../market/market_tab.dart';
import '../media/media_tab.dart';
import '../office/office_tab.dart';
import '../pool/pool_tab.dart';
import '../career/between_screen.dart';
import '../career/career_over_screen.dart';
import '../protection/protection_tab.dart';

/// Ana kabuk: üstte HUD, ortada 5 tab, altta gezinme. Bölüm bitince
/// "aradaki hayat", kariyer bitince sonuç ekranı bunun yerine geçer.
class GameShell extends ConsumerStatefulWidget {
  const GameShell({super.key});

  @override
  ConsumerState<GameShell> createState() => _GameShellState();
}

class _GameShellState extends ConsumerState<GameShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(gameControllerProvider.select((g) => g.phase));

    switch (phase) {
      case GamePhase.between:
        return const BetweenScreen();
      case GamePhase.careerOver:
        return const CareerOverScreen();
      case GamePhase.running:
        break;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const HudBar(),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [
                  OfficeTab(),
                  PoolTab(),
                  MarketTab(),
                  MediaTab(),
                  ProtectionTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Px.panel,
            border: Border(top: BorderSide(color: Px.light, width: Px.unit)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EndWeekButton(),
              PixelTabBar(
                index: _index,
                onChanged: (i) => setState(() => _index = i),
                // Pixel ikonlar tools/make_tab_icons.py ile üretiliyor;
                // beyaz çizilir, burada renklendirilir.
                items: const [
                  ('tab_office', Tr.tabOffice),
                  ('tab_pool', Tr.tabPool),
                  ('tab_market', Tr.tabMarket),
                  ('tab_media', Tr.tabMedia),
                  ('tab_protection', Tr.tabProtection),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kutulu sekme çubuğu. Seçili sekme altın üst çizgiyle öne çıkar, diğerleri
/// içe göçük durur.
class PixelTabBar extends StatelessWidget {
  const PixelTabBar({
    super.key,
    required this.index,
    required this.onChanged,
    required this.items,
  });

  final int index;
  final ValueChanged<int> onChanged;
  /// (ikon dosya adı, etiket). Dosya `assets/icons/<ad>.png`.
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Container(
                  height: 52,
                  decoration: i == index
                      ? const BoxDecoration(
                          color: Px.panelRaised,
                          border: Border(
                            top: BorderSide(color: Px.gold, width: Px.unit),
                            left: BorderSide(color: Px.light, width: 2),
                            right: BorderSide(color: Px.shadow, width: 2),
                            bottom: BorderSide(color: Px.shadow, width: 2),
                          ),
                        )
                      : pixelBevel(fill: Px.inset, raised: false, width: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/${items[i].$1}.png',
                        width: 22,
                        height: 22,
                        color: i == index ? Px.gold : Px.muted,
                        // Pixel art bulanmasın: en yakın komşu.
                        filterQuality: FilterQuality.none,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i].$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 12,
                          height: 1,
                          color: i == index ? Px.text : Px.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (i < items.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}
