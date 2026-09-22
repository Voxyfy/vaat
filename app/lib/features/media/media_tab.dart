import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../../core/strings.dart';
import '../../game/game_controller.dart';

/// Medya: reklam kampanyası ve manşet akışı.
class MediaTab extends ConsumerWidget {
  const MediaTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final ctrl = ref.read(gameControllerProvider.notifier);
    final theme = Theme.of(context);
    final queuedMarketing = game.queued
        .whereType<Marketing>()
        .fold(0.0, (sum, m) => sum + m.amount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(Tr.marketing, style: theme.textTheme.titleMedium),
        Text(Tr.marketingHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        // Wrap, Row degil: dar telefonda iki dugme ve toplam yan yana
        // sigmiyordu. IndexedStack gorunmeyen sekmeleri de yerlestirdigi icin
        // bu tasma baska bir sekmedeyken patliyordu.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => ctrl.queue(const Marketing(50000)),
              child: const Text(Tr.marketingSmall),
            ),
            OutlinedButton(
              onPressed: () => ctrl.queue(const Marketing(250000)),
              child: const Text(Tr.marketingLarge),
            ),
            if (queuedMarketing > 0)
              Text('+${(queuedMarketing / 1000).toStringAsFixed(0)} bin',
                  style: theme.textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 24),
        Text(Tr.headlines, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (game.headlines.isEmpty)
          Text(Tr.noHeadlines, style: theme.textTheme.bodyMedium),
        for (final h in game.headlines.reversed.take(60))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  child: Text('${Tr.week[0]}${h.week}',
                      style: theme.textTheme.labelSmall),
                ),
                Expanded(child: Text(h.text)),
              ],
            ),
          ),
      ],
    );
  }
}
