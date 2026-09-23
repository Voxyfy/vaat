import 'package:flutter/material.dart';

import '../../ui/pixel.dart';

/// Kasa ve ekstre çizgileri. CustomPainter, kütüphane yok.
/// Neden piksel adımlı: pixel art ile aynı dili konuşsun,
/// yumuşak eğri bu oyuna yakışmaz.
class HistoryChart extends StatelessWidget {
  const HistoryChart({
    super.key,
    required this.series,
    this.fromZero = true,
    this.gridLines = 3,
  });

  final List<(List<double>, Color)> series;

  /// Dikey eksen sıfırdan mı başlasın. Kasa ve ekstre için evet: büyüklük
  /// önemli. Piyasa endeksi için hayır: 100 civarındaki dalgalanma görünmeli.
  final bool fromZero;

  /// Yatay kılavuz çizgisi sayısı. Küçük grafiklerde sıfır verilir.
  final int gridLines;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _Painter(series, Px.light, fromZero, gridLines),
        size: Size.infinite,
      );
}

/// Grafiğin altındaki lejant: renk karesi ve ad.
class ChartLegend extends StatelessWidget {
  const ChartLegend(this.items, {super.key});

  final List<(String, Color)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      children: [
        for (final (label, color) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'PixelifySans',
                  fontSize: 12,
                  height: 1,
                  color: Px.muted,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Painter extends CustomPainter {
  _Painter(this.series, this.gridColor, this.fromZero, this.gridLines);

  final List<(List<double>, Color)> series;
  final Color gridColor;
  final bool fromZero;
  final int gridLines;

  @override
  void paint(Canvas canvas, Size size) {
    // Kılavuz: kesikli, soluk. Panelin içe göçük zemini zaten koyu, çizgi
    // yalnız ölçek hissi versin.
    final grid = Paint()
      ..color = gridColor.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (var i = 1; i <= gridLines; i++) {
      final y = (size.height * i / (gridLines + 1)).roundToDouble();
      for (var x = 0.0; x < size.width; x += 6) {
        canvas.drawLine(Offset(x, y), Offset(x + 3, y), grid);
      }
    }

    var maxValue = 1.0;
    var minValue = fromZero ? 0.0 : double.infinity;
    var maxLength = 2;
    for (final (values, _) in series) {
      for (final v in values) {
        if (v > maxValue) maxValue = v;
        if (!fromZero && v < minValue) minValue = v;
      }
      if (values.length > maxLength) maxLength = values.length;
    }
    if (!fromZero) {
      if (minValue == double.infinity) minValue = 0;
      // Düz bir çizgi ekranın ortasında dursun, kenara yapışmasın.
      final pad = (maxValue - minValue) * 0.1;
      minValue -= pad == 0 ? 1 : pad;
      maxValue += pad == 0 ? 1 : pad;
    }
    final span = (maxValue - minValue).abs() < 1e-9 ? 1.0 : maxValue - minValue;

    for (final (values, color) in series) {
      if (values.length < 2) continue;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final path = Path();
      final stepX = size.width / (maxLength - 1);
      var lastY = 0.0;
      for (var i = 0; i < values.length; i++) {
        final x = i * stepX;
        final y = size.height -
            ((values[i].clamp(minValue, maxValue) - minValue) / span) *
                size.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          // Basamak: önce yatay, sonra dikey. Terminal grafiği hissi.
          path.lineTo(x, lastY);
          path.lineTo(x, y);
        }
        lastY = y;
      }
      canvas.drawPath(path, paint);
      // Son değerde küçük kare işaret: "şu an burada".
      final lastX = (values.length - 1) * stepX;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(lastX, lastY), width: 5, height: 5),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Painter old) => true;
}
