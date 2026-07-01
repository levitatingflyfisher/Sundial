import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // Fonts are BUNDLED (assets/fonts/, declared in pubspec) and referenced by
  // family — not fetched from fonts.gstatic.com at runtime. This keeps the app
  // fully local-first: no font egress on first launch. See app_text_styles.dart.
  static const TextTheme _textTheme = TextTheme(
    displayLarge:  TextStyle(fontFamily: 'Lora', fontSize: 57, fontWeight: FontWeight.w700),
    displayMedium: TextStyle(fontFamily: 'Lora', fontSize: 45, fontWeight: FontWeight.w700),
    displaySmall:  TextStyle(fontFamily: 'Lora', fontSize: 36, fontWeight: FontWeight.w700),
    headlineLarge:  TextStyle(fontFamily: 'Lora', fontSize: 32, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontFamily: 'Lora', fontSize: 28, fontWeight: FontWeight.w600),
    headlineSmall:  TextStyle(fontFamily: 'Lora', fontSize: 24, fontWeight: FontWeight.w600),
    titleLarge:  TextStyle(fontFamily: 'Nunito', fontSize: 22, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall:  TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge:  TextStyle(fontFamily: 'Nunito', fontSize: 16),
    bodyMedium: TextStyle(fontFamily: 'Nunito', fontSize: 14),
    bodySmall:  TextStyle(fontFamily: 'Nunito', fontSize: 12),
    labelLarge:  TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall:  TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w500),
  );

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.sage500,
      brightness: Brightness.light,
      surface: AppColors.linen100,
      onSurface: AppColors.linen900,
    ),
    scaffoldBackgroundColor: AppColors.linen100,
    shadowColor: AppColors.linen900.withValues(alpha: 0.15),
    textTheme: _textTheme,
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: AppColors.linen200,
      shadowColor: AppColors.linen900.withValues(alpha: 0.1),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 4,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.sage500,
      brightness: Brightness.dark,
      surface: AppColors.warmDark,
    ),
    scaffoldBackgroundColor: AppColors.warmDark,
    shadowColor: Colors.black.withValues(alpha: 0.3),
    textTheme: _textTheme,
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: AppColors.warmDark2,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 4,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
