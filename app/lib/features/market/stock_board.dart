import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../game/game_controller.dart';
import '../pool/history_chart.dart';

/// Hisse tahtası. Yalnız borsa oynatılan şemalarda görünür.
///
/// Oyunun buradaki kararı tek cümle: şişir, sonra doğru anda sat. Etki
/// haftalar içinde söndüğü için geç kalan kendi balonuyla iniyor.
class StockBoardView extends ConsumerWidget {
  const StockBoardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final board = game.scheme.board;
    final theme = Theme.of(context);

    if (!board.isActive) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(Tr.stockNoBoard, style: theme.textTheme.bodySmall),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(Tr.stockBoard, style: theme.textTheme.titleMedium)),
            Text(
              '${Tr.stockPortfolio} ${money(board.portfolioValue)}',
              style: monoStyle(context, scale: 0.9),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(Tr.stockHeatNote, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        for (final stock in board.stocks) _StockCard(stock: stock),
      ],
    );
  }
}

class _StockCard extends ConsumerWidget {
  const _StockCard({required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(gameControllerProvider.notifier);
    final theme = Theme.of(context);
    final pnl = stock.unrealized;
    final heatColor = stock.heat < 30
        ? Colors.blueGrey
        : stock.heat < 65
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stock.id, style: theme.textTheme.titleSmall),
                      Text(stock.name,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(stock.price.toStringAsFixed(2),
                    style: monoStyle(context, scale: 1.2)),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 44,
              child: HistoryChart(
                series: [(stock.history, theme.colorScheme.primary)],
                fromZero: false,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    stock.shares == 0
                        ? '${Tr.stockPosition}: -'
                        : '${stock.shares} ${Tr.stockLot} · ${money(stock.positionValue)}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (stock.shares > 0)
                  Text(
                    '${pnl >= 0 ? Tr.stockProfit : Tr.stockLoss} ${money(pnl.abs())}',
                    style: monoStyle(context,
                        scale: 0.85,
                        color: pnl >= 0 ? Colors.green : Colors.redAccent),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                SizedBox(
                    width: 34,
                    child: Text(Tr.stockHeat,
                        style: theme.textTheme.labelSmall)),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (stock.heat / 100).clamp(0, 1),
                    minHeight: 5,
                    color: heatColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => ctrl.queue(BuyStock(stock.id, 1000)),
                  child: const Text('${Tr.stockBuy} 1000'),
                ),
                OutlinedButton(
                  onPressed: stock.shares == 0
                      ? null
                      : () => ctrl.queue(SellStock(stock.id, stock.shares)),
                  child: const Text('${Tr.stockSell} ${Tr.stockBoard}'),
                ),
                FilledButton.tonal(
                  onPressed: () => _showOperations(context, ctrl, stock),
                  child: const Text(Tr.stockManipulate),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Operasyon seçimi. Her biri farklı büyüklükte etki ve farklı iz bırakır.
  Future<void> _showOperations(
    BuildContext context,
    GameController ctrl,
    Stock stock,
  ) async {
    const kinds = <(Manipulation, String, String)>[
      (Manipulation.pumpAndDump, Tr.manipPump, Tr.manipPumpNote),
      (Manipulation.washTrade, Tr.manipWash, Tr.manipWashNote),
      (Manipulation.spoof, Tr.manipSpoof, Tr.manipSpoofNote),
      (Manipulation.paintTheTape, Tr.manipTape, Tr.manipTapeNote),
    ];
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text('${stock.id} · ${stock.name}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final (kind, label, note) in kinds)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(label),
                subtitle: Text(
                  '$note\n${Tr.manipCost} ${money(stock.manipulationCost * kind.cashFactor)}',
                ),
                isThreeLine: true,
                onTap: () {
                  ctrl.queue(ManipulateStock(stock.id, kind));
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}
