import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../../core/content.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../game/game_controller.dart';
import 'history_chart.dart';

/// Havuz: gerçek kasa, ekstre toplamı, delik; vaat ve skim kaydıraçları;
/// segment kanalları.
class PoolTab extends ConsumerWidget {
  const PoolTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final ctrl = ref.read(gameControllerProvider.notifier);
    final content = ref.read(contentProvider);
    final cfg = content.balance;
    final type = content.scheme(game.schemeTypeId);
    final s = game.scheme;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _Stat(Tr.realCash, money(s.cash), Colors.green)),
            Expanded(child: _Stat(Tr.promisedTotal, money(s.promisedTotal), Colors.amber)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _Stat(Tr.hole, money(s.hole), Colors.redAccent)),
            Expanded(child: _Stat(Tr.investors, '${s.investorCount}', theme.colorScheme.primary)),
          ],
        ),
        const SizedBox(height: 12),
        Text(Tr.chartTitle, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        SizedBox(
          height: 140,
          child: HistoryChart(
            series: [
              (game.cashHistory, Colors.green),
              (game.promisedHistory, Colors.amber),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SliderRow(
          label: Tr.promisedRate,
          valueText:
              '${pct(game.draftRate, digits: 2)} · ${Tr.promisedRateMonthly} ${pct(game.draftRate * 4.33, digits: 1)}',
          // Üst sınır şema türünden geliyor. Sabit bir tavan kullanmak
          // oyuncuyu yanıltıyordu: kaydıracı yukarı çekiyor, simülasyon türün
          // tavanına kırpıyor ve değer geri düşüyordu.
          hint: '${Tr.schemeCeiling}: ${pct(type.maxRateWeekly, digits: 2)}',
          value: game.draftRate,
          min: 0.0,
          max: type.maxRateWeekly,
          divisions: (type.maxRateWeekly * 1000).round(),
          onChanged: ctrl.setDraftRate,
        ),
        _SliderRow(
          label: Tr.skim,
          valueText: '${pct(game.draftSkim)} · ${Tr.pocket} ${money(s.totalSkimmed)}',
          value: game.draftSkim,
          min: 0.0,
          max: 0.5,
          divisions: 50,
          onChanged: ctrl.setDraftSkim,
        ),
        const SizedBox(height: 20),
        Text(Tr.segments, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final entry in s.segments.entries)
          _SegmentRow(
            cfg: cfg.segments[entry.key]!,
            state: entry.value,
            queuedOpen: game.queued
                .any((a) => a is OpenSegment && a.segmentId == entry.key),
            onOpen: () => ctrl.queue(OpenSegment(entry.key)),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          Text(value, style: monoStyle(context, scale: 1.4, color: color)),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String valueText;
  final String? hint;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
            if (hint != null)
              Text(hint!, style: theme.textTheme.bodySmall),
          ],
        ),
        Text(valueText, style: theme.textTheme.bodySmall),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SegmentRow extends StatelessWidget {
  const _SegmentRow({
    required this.cfg,
    required this.state,
    required this.queuedOpen,
    required this.onOpen,
  });

  final SegmentConfig cfg;
  final SegmentState state;
  final bool queuedOpen;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ListTile yerine kendi satırı: trailing'deki "Kanalı aç" düğmesi dar
    // telefonda satırı taşırıyordu, ayrıca Material görünümü pixel temaya
    // yabancı duruyor.
    final fill = cfg.market == 0 ? 0.0 : state.investors / cfg.market;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(cfg.name)),
              const SizedBox(width: 8),
              if (state.open)
                Text(Tr.channelOpen, style: theme.textTheme.labelSmall)
              else if (queuedOpen)
                Icon(Icons.hourglass_top,
                    size: 18, color: theme.colorScheme.primary)
              else
                TextButton(
                  onPressed: onOpen,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(Tr.openChannel),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            state.open
                ? '${state.investors} / ${cfg.market} · ${money(state.promised)}'
                : '${Tr.channelClosed} · ${Tr.ticket} ${money(cfg.ticket)}',
            style: theme.textTheme.bodySmall,
          ),
          if (state.open) ...[
            const SizedBox(height: 4),
            // Havuz doluluğu: dolduğunda yeni para akışı durur, çöküş yaklaşır.
            LinearProgressIndicator(
              value: fill.clamp(0.0, 1.0),
              minHeight: 4,
              color: fill > 0.8 ? Colors.orange : theme.colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }
}
