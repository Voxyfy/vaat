import 'package:flutter/material.dart';

/// Oyunun tipografi ve renk teması.
///
/// Üç font, üç iş: Pixelify Sans gövde ve etiket, Jersey 20 başlık,
/// Tiny5 sayılar ve HUD. Jacquard 12 yalnız gazete manşetinde, tema içinde
/// değil. Neden ayrı fontlar: tek pixel font hem küçükte okunur hem büyükte
/// sert olamıyor.
///
/// Sayı fontu neden Jersey 20: pixel fontların çoğunda sıfır ortadan çizgili
/// veya noktalı (terminal geleneği) ve ekranda parantez gibi okunuyor. Önce
/// VT323, sonra Tiny5 denendi, ikisi de bu yüzden elendi. Jersey 20'nin sıfırı
/// temiz; rakamları sabit genişlikte değil ama sayılar zaten sağa yaslı
/// kutularda duruyor, tablo hizası bozulmuyor.
abstract final class AppFonts {
  static const body = 'PixelifySans';
  static const display = 'Jersey20';
  static const mono = 'Jersey20';
  static const masthead = 'Jacquard12';
}

/// Pixel fontlar yalnız tasarlandıkları boyutun tam katlarında keskin.
/// Pixelify Sans 16'ya, Jersey 20 20'ye, VT323 20'ye göre çizilmiş.
abstract final class AppSizes {
  static const bodyBase = 16.0;
  static const displayBase = 20.0;
  static const monoBase = 20.0;
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2ECC71),
    brightness: Brightness.dark,
    surface: const Color(0xFF0E1412),
  );

  const display = TextStyle(fontFamily: AppFonts.display, height: 1.0);
  const body = TextStyle(fontFamily: AppFonts.body, height: 1.25);

  final text = TextTheme(
    displayLarge: display.copyWith(fontSize: AppSizes.displayBase * 4),
    displayMedium: display.copyWith(fontSize: AppSizes.displayBase * 3),
    displaySmall: display.copyWith(fontSize: AppSizes.displayBase * 2),
    headlineMedium: display.copyWith(fontSize: AppSizes.displayBase * 2),
    headlineSmall: display.copyWith(fontSize: AppSizes.displayBase * 1.5),
    titleLarge: display.copyWith(fontSize: AppSizes.displayBase * 1.5),
    titleMedium: display.copyWith(fontSize: AppSizes.displayBase),
    titleSmall: body.copyWith(fontSize: AppSizes.bodyBase, fontWeight: FontWeight.w600),
    bodyLarge: body.copyWith(fontSize: AppSizes.bodyBase * 1.25),
    bodyMedium: body.copyWith(fontSize: AppSizes.bodyBase),
    bodySmall: body.copyWith(fontSize: AppSizes.bodyBase, color: scheme.onSurfaceVariant),
    labelLarge: body.copyWith(fontSize: AppSizes.bodyBase, fontWeight: FontWeight.w600),
    labelMedium: body.copyWith(fontSize: AppSizes.bodyBase),
    labelSmall: body.copyWith(fontSize: AppSizes.bodyBase, color: scheme.onSurfaceVariant),
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: AppFonts.body,
    textTheme: text,
    // Yuvarlak köşe pixel dünyaya yabancı; her yerde köşeli.
    cardTheme: const CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: display.copyWith(fontSize: AppSizes.displayBase),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: body.copyWith(fontSize: AppSizes.bodyBase),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: body.copyWith(fontSize: AppSizes.bodyBase),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      labelTextStyle: WidgetStatePropertyAll(
        body.copyWith(fontSize: AppSizes.bodyBase * 0.875),
      ),
    ),
  );
}

/// Sayı metni: tek aralıklı, hizalı. HUD, istatistik ve grafik etiketlerinde.
TextStyle monoStyle(BuildContext context, {double scale = 1, Color? color}) =>
    TextStyle(
      fontFamily: AppFonts.mono,
      fontSize: AppSizes.monoBase * scale,
      height: 1.0,
      color: color,
    );
