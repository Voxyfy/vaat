import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../../core/content.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../game/game_controller.dart';
import '../../ui/pixel.dart';
import '../pool/history_chart.dart';
import 'stock_board.dart';

/// Piyasa: şemanın dışındaki hava. Oyuncunun kontrol edemediği tek sistem,
/// ama çöküşün en sık sebebi.
class MarketTab extends ConsumerWidget {
  const MarketTab({super.key});

  static (String, String, Color) describe(MarketRegime r) => switch (r) {
        MarketRegime.bull => (Tr.marketBull, Tr.marketBullNote, Px.green),
        MarketRegime.normal => (Tr.marketNormal, Tr.marketNormalNote, Px.muted),
        MarketRegime.bear => (Tr.marketBear, Tr.marketBearNote, Px.amber),
        MarketRegime.crash => (Tr.marketCrash, Tr.marketCrashNote, Px.red),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final type = ref.read(contentProvider).scheme(game.schemeTypeId);
    final m = game.scheme.market;
    final theme = Theme.of(context);
    final (label, note, color) = describe(m.regime);
    final up = m.lastChange >= 0;

    // Duyarlılık çarpanı 1'den ne kadar uzaksa etki o kadar sert.
    final sens = type.marketSensitivity;
    final sensLabel = sens < 0.8
        ? Tr.marketSensLow
        : sens < 1.3
            ? Tr.marketSensMid
            : Tr.marketSensHigh;
    double effect(double raw) => 1 + (raw - 1) * sens;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: StatTile(
                label: Tr.marketIndex,
                value: m.index.toStringAsFixed(0),
                icon: Icons.show_chart,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 4,
              child: StatTile(
                label: Tr.marketWeekChange,
                value:
                    '${up ? '+' : ''}${(m.lastChange * 100).toStringAsFixed(1)}%',
                icon: up
                    ? Icons.arrow_drop_up_rounded
                    : Icons.arrow_drop_down_rounded,
                color: up ? Px.green : Px.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PixelPanel(
          title: Tr.marketRegime,
          badge: label,
          badgeColor: color,
          child: Text(note, style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(height: 12),
        PixelPanel(
          title: Tr.marketHistory,
          padding: const EdgeInsets.all(8),
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(6),
            decoration: pixelBevel(fill: Px.inset, raised: false, width: 2),
            child: HistoryChart(
              series: [(game.marketHistory, color)],
              fromZero: false,
            ),
          ),
        ),
        const SizedBox(height: 12),
        PixelPanel(
          title: Tr.marketEffects,
          badge: '${Tr.marketSensShort}: $sensLabel',
          child: Column(
            children: [
              _EffectRow(
                label: Tr.marketInflowEffect,
                icon: Icons.login_rounded,
                multiplier: effect(m.inflowMultiplier),
                goodWhenHigh: true,
              ),
              const SizedBox(height: 6),
              _EffectRow(
                label: Tr.marketWithdrawEffect,
                icon: Icons.logout_rounded,
                multiplier: effect(m.withdrawMultiplier),
                goodWhenHigh: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const StockBoardView(),
      ],
    );
  }
}

/// Piyasanın bu hafta akışa ve çekime uyguladığı çarpan. Çubuk 1,0'ı ortada
/// tutar: sola sapma azalış, sağa sapma artış.
class _EffectRow extends StatelessWidget {
  const _EffectRow({
    required this.label,
    required this.icon,
    required this.multiplier,
    required this.goodWhenHigh,
  });

  final String label;
  final IconData icon;
  final double multiplier;
  final bool goodWhenHigh;

  @override
  Widget build(BuildContext context) {
    final high = multiplier > 1.02;
    final low = multiplier < 0.98;
    final good = (high && goodWhenHigh) || (low && !goodWhenHigh);
    final color = !high && !low
        ? Px.muted
        : good
            ? Px.green
            : Px.red;
    // 0,5x ile 2x arasını çubuğa yay; 1x tam orta.
    final fill = ((multiplier - 0.5) / 1.5).clamp(0.0, 1.0);
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          flex: 30,
          child: Text(label,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          flex: 40,
          child: PixelBar(value: fill, color: color, height: 12, segments: 9),
        ),
        const SizedBox(width: 8),
        Text('×${multiplier.toStringAsFixed(2)}',
            style: monoStyle(context, color: color)),
      ],
    );
  }
}
