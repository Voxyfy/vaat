import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/strings.dart';
import '../../game/game_controller.dart';
import 'end_banner.dart';

/// Kariyer sonu: yakalandın. Defter dökülür, skor yazılır.
class CareerOverScreen extends ConsumerWidget {
  const CareerOverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final theme = Theme.of(context);
    final career = game.career;
    final last = career.chapters.last;
    final collected =
        career.chapters.fold(0.0, (sum, c) => sum + c.collected);
    final victims = career.chapters.fold(0, (sum, c) => sum + c.victims);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            EndBanner(end: last.end),
            const SizedBox(height: 16),
            Text(Tr.careerOverTitle, style: theme.textTheme.titleLarge),
            if (career.overReason != null)
              Text(career.overReason!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            StatRow(Tr.careerChapters, '${career.chapters.length}'),
            StatRow(Tr.careerCollected, money(collected)),
            StatRow(Tr.careerVictims, '$victims'),
            StatRow(Tr.careerScore, money(career.score),
                color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(Tr.careerLog, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final c in career.chapters)
              StatRow(
                '${c.schemeName}\n${c.weeks} hafta',
                '${EndBanner.textsFor(c.end).$1}\n${money(c.tookHome)}',
                numeric: false,
              ),
            const SizedBox(height: 20),
            Text(Tr.realWorldNote, style: theme.textTheme.bodySmall),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: ref.read(gameControllerProvider.notifier).newCareer,
              child: const Text(Tr.newCareer),
            ),
          ],
        ),
      ),
    );
  }
}
