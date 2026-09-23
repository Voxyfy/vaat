/// Para ve yüzde biçimleme. Neden burada: HUD, tablo ve manşet aynı kısaltmayı
/// kullansın; "1.2M" ile "1.200.000" yan yana durmasın.
///
/// Kısaltmalar K / M / B: tycoon oyunlarının ortak dili, dar kutucuğa sığar ve
/// İngilizce sürümde değişmez. "bin / mn" yerine bunlar kullanılıyor.
///
/// "TL" yazıyoruz, ₺ değil: gövde fontu Pixelify Sans'ta ₺ glifi yok, sistem
/// fontuna düşerse pixel görünüm o karakterde kırılır.
String money(double v) {
  final abs = v.abs();
  final sign = v < 0 ? '-' : '';
  if (abs >= 1e9) return '$sign${(abs / 1e9).toStringAsFixed(2)}B TL';
  if (abs >= 1e6) return '$sign${(abs / 1e6).toStringAsFixed(2)}M TL';
  if (abs >= 1e3) return '$sign${(abs / 1e3).toStringAsFixed(0)}K TL';
  return '$sign${abs.toStringAsFixed(0)} TL';
}

String pct(double ratio, {int digits = 0}) =>
    '%${(ratio * 100).toStringAsFixed(digits)}';
