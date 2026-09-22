import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../game/game_controller.dart';

/// Her ekranda sabit üst şerit: bölüm, şema, hafta, karşılama, şüphe ve
/// "Hafta kapat".
///
/// Yerleşim kuralı: hiçbir parça sabit genişlik almaz. Pixel fontlar geniş,
/// metinler Türkçe ve uzun; dar telefonda tek bir sabit ölçü bile satırı
/// taşırıyor. Sol blok esner, düğme esner, barların etiketleri esner.
class HudBar extends ConsumerWidget {
  const HudBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final s = game.scheme;
    final type = ref.read(contentProvider).scheme(game.schemeTypeId);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kariyer boyunca şema değiştiği için adı burada duruyor.
                    Text(
                      '${Tr.chapterShort}${game.career.chapter} · ${type.name}',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${Tr.week.toUpperCase()} ${s.week}',
                      key: const Key('hud-week'),
                      style: monoStyle(context, scale: 1.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: FilledButton(
                  onPressed: game.busy || s.isOver
                      ? null
                      : () =>
                          ref.read(gameControllerProvider.notifier).endWeek(),
                  child: Text(
                    s.isOver
                        ? Tr.schemeOver
                        : game.busy
                            ? Tr.endWeekBusy
                            : Tr.endWeek,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Bar(
            label: Tr.coverage,
            // Karşılama %150'yi geçince bar dolu kalsın; asıl merak edilen
            // düşüş tarafı.
            value: s.coverage.clamp(0.0, 1.5) / 1.5,
            text: pct(s.coverage),
            color: s.coverage >= 1
                ? Colors.green
                : s.coverage >= 0.3
                    ? Colors.amber
                    : Colors.redAccent,
          ),
          const SizedBox(height: 4),
          _Bar(
            label: Tr.suspicion,
            value: s.suspicion / 100,
            text: s.suspicion.toStringAsFixed(0),
            color: s.suspicion < 40
                ? Colors.blueGrey
                : s.suspicion < 70
                    ? Colors.orange
                    : Colors.red,
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.text,
    required this.color,
  });

  final String label;
  final double value;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    // Etiket ve sayı esnek paylarla yer alıyor; sabit genişlik vermek
    // uzun etiketlerde satırı taşırıyordu.
    return Row(
      children: [
        Expanded(
          flex: 30,
          child: Text(label,
              style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          flex: 55,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 15,
          child: Text(text,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: monoStyle(context, scale: 0.9)),
        ),
      ],
    );
  }
}
