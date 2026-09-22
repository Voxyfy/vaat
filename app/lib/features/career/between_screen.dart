import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../../core/content.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../game/game_controller.dart';
import 'asset_shop.dart';
import 'end_banner.dart';

/// "Aradaki hayat": bölüm bitti, para sayılıyor, sıradaki iş seçiliyor.
///
/// Neden ayrı tam ekran: burada zaman akmıyor, HUD'un ve sekmelerin anlamı
/// yok. Oyuncu istediği kadar kalır.
class BetweenScreen extends ConsumerWidget {
  const BetweenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final ctrl = ref.read(gameControllerProvider.notifier);
    final content = ref.read(contentProvider);
    final theme = Theme.of(context);
    final career = game.career;
    final last = career.chapters.last;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            EndBanner(end: last.end),
            const SizedBox(height: 20),
            StatRow(Tr.week, '${last.weeks}'),
            StatRow(Tr.totalInflow, money(last.collected)),
            StatRow(Tr.victims, '${last.victims}'),
            StatRow(Tr.tookHome, money(last.tookHome), color: Colors.green),
            const SizedBox(height: 28),

            Text(Tr.betweenTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            StatRow(Tr.cleanMoney, money(career.cleanMoney)),
            StatRow(Tr.dirtyMoney, money(career.dirtyMoney)),
            StatRow(Tr.usableCapital, money(career.usableCapital),
                color: theme.colorScheme.primary),
            Text(Tr.dirtyNote, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            StatRow(Tr.record, career.record.toStringAsFixed(0),
                color: career.record > 50 ? Colors.orange : null),
            LinearProgressIndicator(
              value: career.record / 100,
              minHeight: 8,
              color: career.record > 50 ? Colors.orange : Colors.blueGrey,
            ),
            const SizedBox(height: 4),
            Text(Tr.recordNote, style: theme.textTheme.bodySmall),
            const SizedBox(height: 28),

            const AssetShop(),
            const SizedBox(height: 28),

            Text(Tr.chooseScheme, style: theme.textTheme.titleLarge),
            Text(Tr.chooseSchemeNote, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            for (final id in game.offers)
              _SchemeCard(
                type: content.scheme(id),
                onPick: () => ctrl.chooseScheme(id),
              ),
          ],
        ),
      ),
    );
  }
}

class _SchemeCard extends StatelessWidget {
  const _SchemeCard({required this.type, required this.onPick});

  final SchemeType type;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(type.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(type.pitch),
            const SizedBox(height: 12),
            StatRow(Tr.schemeCover, type.cover, numeric: false),
            StatRow(Tr.schemeStartRate, pct(type.startRateWeekly, digits: 2)),
            StatRow(Tr.schemeCeiling, pct(type.maxRateWeekly, digits: 1)),
            const SizedBox(height: 12),
            FilledButton(onPressed: onPick, child: const Text(Tr.schemeStart)),
          ],
        ),
      ),
    );
  }
}
