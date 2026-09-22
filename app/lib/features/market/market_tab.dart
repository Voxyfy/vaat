import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../../core/content.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../game/game_controller.dart';
import '../pool/history_chart.dart';
import 'stock_board.dart';

/// Piyasa: şemanın dışındaki hava. Oyuncunun kontrol edemediği tek sistem,
/// ama çöküşün en sık sebebi.
class MarketTab extends ConsumerWidget {
  const MarketTab({super.key});

  static (String, String, Color) describe(MarketRegime r) => switch (r) {
        MarketRegime.bull => (Tr.marketBull, Tr.marketBullNote, Colors.green),
        MarketRegime.normal =>
          (Tr.marketNormal, Tr.marketNormalNote, Colors.blueGrey),
        MarketRegime.bear => (Tr.marketBear, Tr.marketBearNote, Colors.orange),
        MarketRegime.crash => (Tr.marketCrash, Tr.marketCrashNote, Colors.red),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final type = ref.read(contentProvider).scheme(game.schemeTypeId);
    final m = game.scheme.market;
    final theme = Theme.of(context);
    final (label, note, color) = describe(m.regime);

    // Duyarlılık çarpanı 1'den ne kadar uzaksa etki o kadar sert.
    final sens = type.marketSensitivity;
    final sensLabel = sens < 0.8
        ? Tr.marketSensLow
        : sens < 1.3
            ? Tr.marketSensMid
            : Tr.marketSensHigh;
    double effect(double raw) => 1 + (raw - 1) * sens;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(Tr.marketIndex, style: theme.textTheme.labelLarge),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(m.index.toStringAsFixed(0),
                style: monoStyle(context, scale: 2.2, color: color)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${Tr.marketWeekChange} ${m.lastChange >= 0 ? '+' : ''}'
                '${(m.lastChange * 100).toStringAsFixed(1)}%',
                style: monoStyle(
                  context,
                  color: m.lastChange >= 0 ? Colors.green : Colors.redAccent,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          color: color.withValues(alpha: 0.12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(Tr.marketRegime, style: theme.textTheme.labelMedium),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(label,
                        style: theme.textTheme.titleMedium?.copyWith(color: color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(note, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(Tr.marketHistory, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        SizedBox(
          height: 120,
          child: HistoryChart(
            series: [(game.marketHistory, color)],
            fromZero: false,
          ),
        ),
        const SizedBox(height: 20),
        Text('${Tr.marketSensitivity}: $sensLabel',
            style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _EffectRow(
          label: Tr.marketInflowEffect,
          multiplier: effect(m.inflowMultiplier),
          goodWhenHigh: true,
        ),
        _EffectRow(
          label: Tr.marketWithdrawEffect,
          multiplier: effect(m.withdrawMultiplier),
          goodWhenHigh: false,
        ),
        const SizedBox(height: 24),
        const StockBoardView(),
      ],
    );
  }
}

/// Piyasanın bu hafta akışa ve çekime uyguladığı çarpan.
class _EffectRow extends StatelessWidget {
  const _EffectRow({
    required this.label,
    required this.multiplier,
    required this.goodWhenHigh,
  });

  final String label;
  final double multiplier;
  final bool goodWhenHigh;

  @override
  Widget build(BuildContext context) {
    final high = multiplier > 1.02;
    final low = multiplier < 0.98;
    final good = (high && goodWhenHigh) || (low && !goodWhenHigh);
    final color = !high && !low
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : good
            ? Colors.green
            : Colors.redAccent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text('×${multiplier.toStringAsFixed(2)}',
              style: monoStyle(context, color: color)),
        ],
      ),
    );
  }
}
