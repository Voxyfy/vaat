import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../game/game_controller.dart';
import '../../ui/pixel.dart';
import 'end_banner.dart';
import 'retire_section.dart';

/// Kariyer sonu. Yakalandın ya da kendin çekildin; defter dökülür, skor yazılır.
class CareerOverScreen extends ConsumerWidget {
  const CareerOverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final theme = Theme.of(context);
    final career = game.career;
    final last = career.chapters.last;
    final ending = career.ending ?? CareerEnding.prison;
    final prison = ending == CareerEnding.prison;

    return Scaffold(
      backgroundColor: Px.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          children: [
            // Yakalanma manşeti şemanın sonundan gelir; kendi çekilen
            // oyuncunun manşeti seçtiği sondur.
            if (prison)
              EndBanner(end: last.end)
            else
              EndBanner.custom(
                title: EndingTexts.name(ending).toUpperCase(),
                sub: EndingTexts.note(ending),
              ),
            const SizedBox(height: 16),
            Text(
              Tr.careerOverTitle,
              style: theme.textTheme.displaySmall?.copyWith(color: Px.gold),
            ),
            if (prison) ...[
              if (career.overReason != null)
                Text(career.overReason!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(EndingTexts.note(ending), style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 14),

            PixelPanel(
              title: Tr.careerScore,
              badge: '×${ending.multiplier.toStringAsFixed(1)}',
              badgeColor: ending.multiplier > 0 ? Px.gold : Px.red,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Skor iri: ekranın tek "sonuç" sayısı.
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration:
                        pixelBevel(fill: Px.inset, raised: false, width: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events_outlined,
                            color: Px.gold, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              money(career.score),
                              style: TextStyle(
                                fontFamily: AppFonts.mono,
                                fontSize: AppSizes.monoBase * 2.2,
                                height: 1,
                                color: Px.gold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: Tr.careerEnding,
                          value: EndingTexts.name(ending),
                          icon: EndingTexts.icon(ending),
                          color: prison ? Px.red : Px.text,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: prison
                            ? StatTile(
                                label: Tr.prisonYears,
                                value:
                                    '${career.prisonYears} ${Tr.yearsSuffix}',
                                icon: Icons.gavel_outlined,
                                color: Px.red,
                              )
                            : StatTile(
                                label: Tr.careerChapters,
                                value: '${career.chapters.length}',
                                icon: Icons.menu_book_outlined,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: Tr.careerCollected,
                          value: money(career.totalCollected),
                          icon: Icons.download_outlined,
                          color: Px.amber,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: StatTile(
                          label: Tr.careerVictims,
                          value: '${career.totalVictims}',
                          icon: Icons.groups_outlined,
                          color: Px.red,
                        ),
                      ),
                    ],
                  ),
                  if (prison) ...[
                    const SizedBox(height: 6),
                    StatTile(
                      label: Tr.careerChapters,
                      value: '${career.chapters.length}',
                      icon: Icons.menu_book_outlined,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            PixelPanel(
              title: Tr.careerLog,
              badge: '${career.chapters.length}',
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              child: Column(
                children: [
                  for (final (i, c) in career.chapters.indexed)
                    _LogRow(chapter: c, isLast: i == career.chapters.length - 1),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(Tr.realWorldNote,
                style: theme.textTheme.bodySmall?.copyWith(color: Px.muted)),
            const SizedBox(height: 20),
            PixelButton(
              label: Tr.newCareer,
              kind: PixelButtonKind.primary,
              icon: Icons.replay_rounded,
              onPressed: ref.read(gameControllerProvider.notifier).newCareer,
            ),
          ],
        ),
      ),
    );
  }
}

/// Defterde tek bölüm: şema, hafta, sonuç rozeti, yanına alınan para.
class _LogRow extends StatelessWidget {
  const _LogRow({required this.chapter, required this.isLast});

  final ChapterRecord chapter;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = EndBanner.colorFor(chapter.end);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: Px.shadow, width: 2)),
            ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chapter.schemeName,
                    style: theme.textTheme.bodyMedium, maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${chapter.weeks} ${Tr.week.toLowerCase()}',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PixelTag(EndBanner.textsFor(chapter.end).$1, color: color),
          const SizedBox(width: 10),
          Text(money(chapter.tookHome),
              style: monoStyle(context, scale: 0.9, color: Px.green)),
        ],
      ),
    );
  }
}
