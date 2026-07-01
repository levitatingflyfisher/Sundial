import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // Fonts are BUNDLED (assets/fonts/, declared in pubspec) and referenced by
  // family — not fetched from fonts.gstatic.com at runtime. This keeps the app
  // fully local-first: no font egress on first launch. See app_text_styles.dart.
  //
  // The ladder itself is the fleet-canonical Material-scale TextTheme from
  // openhearth_design — byte-identical to the block Sundial used to hand-roll
  // (asserted in test/shared/theme/design_sync_test.dart), so adopting it is
  // zero visual change by construction.
  static const TextTheme _textTheme = OhTypography.materialTextTheme;

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
