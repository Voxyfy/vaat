import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../game/game_controller.dart';
import '../../ui/pixel.dart';

/// Her ekranda sabit üst şerit: bölüm ve şema, hafta, üç kaynak kutucuğu
/// (kasa, delik, yatırımcı) ve iki çubuk (karşılama, şüphe).
///
/// "Hafta kapat" artık burada değil, alt sekme çubuğunun üstündeki iri
/// düğmede: başparmağın ulaştığı yerde ve her sekmede aynı noktada.
///
/// Yerleşim kuralı: hiçbir parça sabit genişlik almaz. Pixel fontlar geniş,
/// metinler Türkçe ve uzun; dar telefonda tek bir sabit ölçü bile satırı
/// taşırıyor.
class HudBar extends ConsumerWidget {
  const HudBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final s = game.scheme;
    final type = ref.read(contentProvider).scheme(game.schemeTypeId);

    final coverageColor = s.coverage >= 1
        ? Px.green
        : s.coverage >= 0.3
            ? Px.amber
            : Px.red;
    final suspicionColor = s.suspicion < 40
        ? Px.blue
        : s.suspicion < 70
            ? Px.amber
            : Px.red;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: const BoxDecoration(
        color: Px.panel,
        border: Border(bottom: BorderSide(color: Px.shadow, width: Px.unit)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Kariyer boyunca şema değiştiği için adı burada duruyor.
              Expanded(
                child: Text(
                  '${Tr.chapterShort}${game.career.chapter} · ${type.name}'
                      .toUpperCase(),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: AppSizes.displayBase,
                    height: 1,
                    color: Px.gold,
                    letterSpacing: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 3),
                decoration: pixelBevel(fill: Px.inset, raised: false, width: 2),
                child: Text(
                  '${Tr.week.toUpperCase()} ${s.week}',
                  key: const Key('hud-week'),
                  style: monoStyle(context, scale: 1.0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: Tr.cashShort,
                  value: money(s.cash),
                  icon: Icons.savings_outlined,
                  color: s.cash >= 0 ? Px.green : Px.red,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                // Kasa ekstreleri aşıyorsa "delik" yok, fazla var; etiket de
                // renk de buna göre değişir. Eksi işaretli delik kafa
                // karıştırıyordu.
                child: StatTile(
                  label: s.hole > 0 ? Tr.hole : Tr.surplus,
                  value: money(s.hole.abs()),
                  icon: s.hole > 0
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: s.hole > 0 ? Px.red : Px.green,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: StatTile(
                  label: Tr.investors,
                  value: '${s.investorCount}',
                  icon: Icons.groups_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PixelBar(
            label: Tr.coverage,
            // Karşılama %150'yi geçince bar dolu kalsın; asıl merak edilen
            // düşüş tarafı.
            value: s.coverage.clamp(0.0, 1.5) / 1.5,
            text: pct(s.coverage),
            color: coverageColor,
          ),
          const SizedBox(height: 5),
          PixelBar(
            label: Tr.suspicion,
            value: s.suspicion / 100,
            text: s.suspicion.toStringAsFixed(0),
            color: suspicionColor,
          ),
        ],
      ),
    );
  }
}

/// Alt çubuğun üstündeki iri "Hafta kapat". Tycoon oyunlarında tek ana
/// hamle her zaman aynı yerde durur; burada da öyle.
class EndWeekButton extends ConsumerWidget {
  const EndWeekButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final s = game.scheme;
    final pending = s.pendingEventIds.length;
    final unanswered = pending - game.answers.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: PixelButton(
        label: s.isOver
            ? Tr.schemeOver
            : game.busy
                ? Tr.endWeekBusy
                : Tr.endWeek,
        icon: Icons.fast_forward_rounded,
        kind: PixelButtonKind.primary,
        // Cevapsız dosya varsa düğme bunu söyler: görmezden gelmek bir
        // karardır ama en azından bilinçli olsun.
        cost: unanswered > 0 ? '$unanswered ${Tr.unansweredShort}' : null,
        costColor: Px.ink,
        onPressed: game.busy || s.isOver
            ? null
            : () => ref.read(gameControllerProvider.notifier).endWeek(),
      ),
    );
  }
}
