/// Para ve yüzde biçimleme. Neden burada: HUD, tablo ve manşet aynı kısaltmayı
/// kullansın; "1.2 mn" ile "1.200.000" yan yana durmasın.
///
/// "TL" yazıyoruz, ₺ değil: gövde fontu Pixelify Sans'ta ₺ glifi yok, sistem
/// fontuna düşerse pixel görünüm o karakterde kırılır.
String money(double v) {
  final abs = v.abs();
  final sign = v < 0 ? '-' : '';
  if (abs >= 1e9) return '$sign${(abs / 1e9).toStringAsFixed(2)} mr TL';
  if (abs >= 1e6) return '$sign${(abs / 1e6).toStringAsFixed(2)} mn TL';
  if (abs >= 1e3) return '$sign${(abs / 1e3).toStringAsFixed(0)} bin TL';
  return '$sign${abs.toStringAsFixed(0)} TL';
}

String pct(double ratio, {int digits = 0}) =>
    '%${(ratio * 100).toStringAsFixed(digits)}';
