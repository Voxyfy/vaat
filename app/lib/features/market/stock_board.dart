import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../game/game_controller.dart';
import '../../ui/pixel.dart';
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
      return PixelPanel(
        margin: const EdgeInsets.only(top: 8),
        fill: Px.inset,
        raised: false,
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: Px.muted, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(Tr.stockNoBoard, style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      );
    }

    final pnl = board.unrealized;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(Tr.stockBoard, trailing: '${board.stocks.length}'),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: Tr.stockPortfolio,
                value: money(board.portfolioValue),
                icon: Icons.account_balance_outlined,
                color: Px.gold,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: StatTile(
                label: pnl >= 0 ? Tr.stockProfit : Tr.stockLoss,
                value: money(pnl.abs()),
                icon: pnl >= 0
                    ? Icons.arrow_drop_up_rounded
                    : Icons.arrow_drop_down_rounded,
                color: pnl >= 0 ? Px.green : Px.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
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
    final pnl = stock.unrealized;
    final heatColor = stock.heat < 30
        ? Px.blue
        : stock.heat < 65
            ? Px.amber
            : Px.red;
    final hasPosition = stock.shares > 0;
    // Son iki kapanışa göre yön: grafiğin rengi bunu söyler.
    final h = stock.history;
    final up = h.length < 2 || h.last >= h[h.length - 2];
    final trend = up ? Px.green : Px.red;

    return PixelPanel(
      title: '${stock.id} · ${stock.name}',
      badge: hasPosition ? '${stock.shares} ${Tr.stockLot}' : null,
      badgeColor: Px.gold,
      margin: const EdgeInsets.only(bottom: 10),
      fill: Px.panelRaised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                decoration: pixelBevel(fill: Px.inset, raised: false, width: 2),
                child: Text(
                  stock.price.toStringAsFixed(2),
                  style: monoStyle(context, scale: 1.5, color: trend),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration:
                      pixelBevel(fill: Px.inset, raised: false, width: 2),
                  child: HistoryChart(
                    series: [(stock.history, trend)],
                    fromZero: false,
                    gridLines: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: Tr.stockPosition,
                  value: hasPosition ? money(stock.positionValue) : '-',
                  color: hasPosition ? Px.text : Px.muted,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: StatTile(
                  label: Tr.stockAvgCost,
                  value: hasPosition ? stock.avgCost.toStringAsFixed(2) : '-',
                  color: hasPosition ? Px.text : Px.muted,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: StatTile(
                  label: pnl >= 0 ? Tr.stockProfit : Tr.stockLoss,
                  value: hasPosition ? money(pnl.abs()) : '-',
                  color: !hasPosition
                      ? Px.muted
                      : pnl >= 0
                          ? Px.green
                          : Px.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PixelBar(
            label: Tr.stockHeat,
            value: (stock.heat / 100).clamp(0, 1),
            text: stock.heat.toStringAsFixed(0),
            color: heatColor,
            height: 12,
          ),
          const SizedBox(height: 10),
          // Al ve sat alt alta: yan yana dururken maliyet rozeti dar
          // telefonda taşıyordu.
          PixelButton(
            label: '${Tr.stockBuy} 1000 ${Tr.stockLot}',
            dense: true,
            icon: Icons.add_rounded,
            cost: money(-stock.price * 1000),
            costColor: Px.amber,
            onPressed: () => ctrl.queue(BuyStock(stock.id, 1000)),
          ),
          const SizedBox(height: 6),
          PixelButton(
            label: '${Tr.stockSell} ${hasPosition ? stock.shares : 0} ${Tr.stockLot}',
            dense: true,
            icon: Icons.remove_rounded,
            cost: hasPosition ? money(stock.positionValue) : null,
            costColor: Px.green,
            onPressed: hasPosition
                ? () => ctrl.queue(SellStock(stock.id, stock.shares))
                : null,
          ),
          const SizedBox(height: 6),
          PixelButton(
            label: Tr.stockManipulate,
            kind: PixelButtonKind.danger,
            dense: true,
            icon: Icons.bolt_rounded,
            onPressed: () => _showOperations(context, ctrl, stock),
          ),
        ],
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
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Px.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(12),
          children: [
            PixelPanel(
              title: Tr.stockOperations,
              badge: stock.id,
              badgeColor: Px.gold,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(stock.name, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 10),
                  for (final (kind, label, note) in kinds) ...[
                    PixelButton(
                      label: label,
                      kind: PixelButtonKind.danger,
                      cost: money(-stock.manipulationCost * kind.cashFactor),
                      costColor: Colors.white,
                      onPressed: () {
                        ctrl.queue(ManipulateStock(stock.id, kind));
                        Navigator.of(context).pop();
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 0, 10),
                      child: Text(note, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
