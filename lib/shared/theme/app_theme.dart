import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static TextTheme get _textTheme => TextTheme(
    displayLarge:  GoogleFonts.lora(fontSize: 57, fontWeight: FontWeight.w700),
    displayMedium: GoogleFonts.lora(fontSize: 45, fontWeight: FontWeight.w700),
    displaySmall:  GoogleFonts.lora(fontSize: 36, fontWeight: FontWeight.w700),
    headlineLarge:  GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.w700),
    headlineMedium: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.w600),
    headlineSmall:  GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.w600),
    titleLarge:  GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w700),
    titleMedium: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall:  GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge:  GoogleFonts.nunito(fontSize: 16),
    bodyMedium: GoogleFonts.nunito(fontSize: 14),
    bodySmall:  GoogleFonts.nunito(fontSize: 12),
    labelLarge:  GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall:  GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w500),
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
