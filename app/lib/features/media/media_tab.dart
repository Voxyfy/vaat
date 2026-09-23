import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../game/game_controller.dart';
import '../../game/game_state.dart';
import '../../ui/pixel.dart';

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
      padding: const EdgeInsets.all(12),
      children: [
        PixelPanel(
          title: Tr.marketing,
          badge: queuedMarketing > 0 ? Tr.marketingQueued : null,
          badgeColor: Px.gold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(Tr.marketingHint, style: theme.textTheme.bodySmall),
              const SizedBox(height: 10),
              // İki bütçe alt alta, tutar rozette. Yan yana koyunca 393
              // genişlikte ikon + etiket + rozet sığmıyor ve taşıyor.
              PixelButton(
                label: Tr.marketingSmallLabel,
                icon: Icons.campaign_outlined,
                cost: money(-50000),
                onPressed: () => ctrl.queue(const Marketing(50000)),
              ),
              const SizedBox(height: 6),
              PixelButton(
                label: Tr.marketingLargeLabel,
                icon: Icons.campaign_outlined,
                cost: money(-250000),
                onPressed: () => ctrl.queue(const Marketing(250000)),
              ),
              if (queuedMarketing > 0) ...[
                const SizedBox(height: 8),
                StatTile(
                  label: Tr.marketingTotalQueued,
                  value: money(-queuedMarketing),
                  icon: Icons.schedule_rounded,
                  color: Px.amber,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        PixelPanel(
          title: Tr.headlines,
          badge: game.headlines.isEmpty ? null : '${game.headlines.length}',
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: game.headlines.isEmpty
              ? Row(
                  children: [
                    const Icon(Icons.newspaper_outlined, color: Px.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(Tr.noHeadlines,
                          style: theme.textTheme.bodyMedium),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final h in game.headlines.reversed.take(60))
                      _HeadlineRow(h),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Tek manşet satırı: solda hafta kutusu, sağda metin. Olay satırları
/// kırmızı sol şeritle ayrılır; cevapsız kalan kart notu soluk.
class _HeadlineRow extends StatelessWidget {
  const _HeadlineRow(this.headline);

  final Headline headline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEvent = headline.text.startsWith(Tr.headlineEventPrefix);
    final auto = headline.text.endsWith(Tr.headlineAutoSuffix);
    final text = auto
        ? headline.text
            .substring(0, headline.text.length - Tr.headlineAutoSuffix.length)
            .trimRight()
        : headline.text;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isEvent ? Px.panelRaised : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: isEvent ? Px.red : Px.light,
            width: Px.unit,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 5, 6, 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(5, 3, 5, 2),
            decoration: pixelBevel(fill: Px.inset, raised: false, width: 2),
            child: Text(
              '${Tr.week[0]}${headline.week}',
              style: monoStyle(context, scale: 0.8, color: Px.muted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: text,
                    style: isEvent
                        ? theme.textTheme.bodyMedium
                            ?.copyWith(color: Px.text)
                        : theme.textTheme.bodyMedium,
                  ),
                  if (auto)
                    TextSpan(
                      text: ' ${Tr.headlineAutoSuffix}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Px.muted),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
