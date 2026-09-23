import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../../core/content.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../game/game_controller.dart';
import '../../ui/pixel.dart';
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

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: Tr.realCash,
                value: money(s.cash),
                icon: Icons.savings_outlined,
                color: s.cash >= 0 ? Px.green : Px.red,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: StatTile(
                label: Tr.promisedTotal,
                value: money(s.promisedTotal),
                icon: Icons.receipt_long_outlined,
                color: Px.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: Tr.hole,
                value: money(-s.hole),
                icon: Icons.warning_amber_rounded,
                color: s.hole <= 0 ? Px.green : Px.red,
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
        const SizedBox(height: 12),
        PixelPanel(
          title: Tr.chartTitle,
          badge: '${Tr.week} ${s.week}',
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                padding: const EdgeInsets.all(6),
                decoration: pixelBevel(fill: Px.inset, raised: false, width: 2),
                child: HistoryChart(
                  series: [
                    (game.cashHistory, Px.green),
                    (game.promisedHistory, Px.gold),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const ChartLegend([
                (Tr.legendCash, Px.green),
                (Tr.legendPromised, Px.gold),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SliderPanel(
          title: Tr.promiseShort,
          label: Tr.promisedRate,
          bigValue: pct(game.draftRate, digits: 2),
          smallValue:
              '${Tr.promisedRateMonthly} ${pct(game.draftRate * 4.33, digits: 1)}',
          // Üst sınır şema türünden geliyor. Sabit bir tavan kullanmak
          // oyuncuyu yanıltıyordu: kaydıracı yukarı çekiyor, simülasyon türün
          // tavanına kırpıyor ve değer geri düşüyordu.
          badge: '${Tr.schemeCeiling} ${pct(type.maxRateWeekly, digits: 1)}',
          value: game.draftRate,
          min: 0.0,
          max: type.maxRateWeekly,
          divisions: (type.maxRateWeekly * 1000).round(),
          onChanged: ctrl.setDraftRate,
          // Vaat yükseldikçe renk kızarır: tavana yakın vaat çöküşün adresi.
          color: game.draftRate / type.maxRateWeekly < 0.5
              ? Px.gold
              : game.draftRate / type.maxRateWeekly < 0.8
                  ? Px.amber
                  : Px.red,
        ),
        const SizedBox(height: 12),
        _SliderPanel(
          title: Tr.skimShort,
          label: Tr.skim,
          bigValue: pct(game.draftSkim),
          smallValue: '${Tr.pocket} ${money(s.totalSkimmed)}',
          value: game.draftSkim,
          min: 0.0,
          max: 0.5,
          divisions: 50,
          onChanged: ctrl.setDraftSkim,
          color: Px.green,
        ),
        SectionHeader(Tr.segments,
            trailing:
                '${s.segments.values.where((v) => v.open).length}/${s.segments.length}'),
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

/// Başlıklı kaydıraç paneli. Sol altta açıklama, sağda iri sayı, altta
/// altın izli kaydıraç.
class _SliderPanel extends StatelessWidget {
  const _SliderPanel({
    required this.title,
    required this.label,
    required this.bigValue,
    required this.smallValue,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.color,
    this.badge,
  });

  final String title;
  final String label;
  final String bigValue;
  final String smallValue;
  final String? badge;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PixelPanel(
      title: title,
      badge: badge,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    Text(smallValue, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                decoration: pixelBevel(fill: Px.inset, raised: false, width: 2),
                child: Text(
                  bigValue,
                  style: monoStyle(context, scale: 1.5, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 10,
              trackShape: const RectangularSliderTrackShape(),
              activeTrackColor: color,
              inactiveTrackColor: Px.inset,
              thumbShape: const _SquareThumb(),
              thumbColor: Px.text,
              overlayShape: SliderComponentShape.noOverlay,
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kare kaydıraç tutamağı. Yuvarlak tutamak pixel dünyaya yabancı.
class _SquareThumb extends SliderComponentShape {
  const _SquareThumb();

  static const _size = 20.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(_size, _size);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final rect = Rect.fromCenter(center: center, width: _size, height: _size);
    // Kabartma: gövde açık, alt-sağ kenar gölge, üst-sol kenar ışık.
    canvas.drawRect(rect, Paint()..color = Px.shadow);
    canvas.drawRect(rect.deflate(3), Paint()..color = Px.text);
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 3, rect.top + 3, _size - 6, 3),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 3, rect.bottom - 6, _size - 6, 3),
      Paint()..color = Px.muted,
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
    final fill = cfg.market == 0 ? 0.0 : state.investors / cfg.market;
    // Havuz doluluğu: dolduğunda yeni para akışı durur, çöküş yaklaşır.
    final fillColor = fill > 0.8 ? Px.amber : Px.green;

    return PixelPanel(
      margin: const EdgeInsets.only(bottom: 8),
      fill: state.open ? Px.panel : Px.inset,
      raised: state.open,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  cfg.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: state.open ? Px.text : Px.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (state.open)
                const PixelTag(Tr.channelOpen, color: Px.green)
              else if (queuedOpen)
                const PixelTag(Tr.queuedShort, color: Px.gold)
              else
                const PixelTag(Tr.channelClosed),
            ],
          ),
          const SizedBox(height: 6),
          if (state.open) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${state.investors} / ${cfg.market} ${Tr.investors.toLowerCase()}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(money(state.promised),
                    style: monoStyle(context, scale: 0.9, color: Px.gold)),
              ],
            ),
            const SizedBox(height: 6),
            PixelBar(value: fill, color: fillColor, height: 12),
          ] else ...[
            Text(
              '${Tr.ticket} ${money(cfg.ticket)} · ${cfg.market} ${Tr.capacityShort}',
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!queuedOpen) ...[
              const SizedBox(height: 8),
              // Düğme tam satır: dar telefonda ad ve maliyet rozeti aynı
              // satıra sığmıyordu.
              PixelButton(
                label: Tr.openChannel,
                dense: true,
                icon: Icons.lock_open_rounded,
                cost: money(-const OpenSegment('').setupCost),
                costColor: Px.amber,
                onPressed: onOpen,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
