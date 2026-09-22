import 'package:flutter/material.dart';

/// Kasa ve ekstre çizgileri. CustomPainter, kütüphane yok.
/// Neden piksel adımlı: ileride pixel art ile aynı dili konuşsun,
/// yumuşak eğri bu oyuna yakışmaz.
class HistoryChart extends StatelessWidget {
  const HistoryChart({
    super.key,
    required this.series,
    this.fromZero = true,
  });

  final List<(List<double>, Color)> series;

  /// Dikey eksen sıfırdan mı başlasın. Kasa ve ekstre için evet: büyüklük
  /// önemli. Piyasa endeksi için hayır: 100 civarındaki dalgalanma görünmeli.
  final bool fromZero;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _Painter(
            series, Theme.of(context).colorScheme.outlineVariant, fromZero),
        size: Size.infinite,
      );
}

class _Painter extends CustomPainter {
  _Painter(this.series, this.gridColor, this.fromZero);

  final List<(List<double>, Color)> series;
  final Color gridColor;
  final bool fromZero;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
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
    }
  }

  @override
  bool shouldRepaint(covariant _Painter old) => true;
}
