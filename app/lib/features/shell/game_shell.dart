import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../game/game_controller.dart';
import '../../game/game_state.dart';
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.business_outlined), label: Tr.tabOffice),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: Tr.tabPool),
          NavigationDestination(
              icon: Icon(Icons.show_chart), label: Tr.tabMarket),
          NavigationDestination(
              icon: Icon(Icons.campaign_outlined), label: Tr.tabMedia),
          NavigationDestination(
              icon: Icon(Icons.shield_outlined), label: Tr.tabProtection),
        ],
      ),
    );
  }
}
