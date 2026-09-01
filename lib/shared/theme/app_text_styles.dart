import 'package:flutter/material.dart';

// Lora/Nunito are openhearth_design's package fonts (0.7.2+), not a local
// copy — `package: 'openhearth_design'` is required or these names resolve
// to nothing and fall back to the platform font.
const _designPackage = 'openhearth_design';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get timerDisplay => const TextStyle(
    fontFamily: 'Lora',
    package: _designPackage,
    fontSize: 56,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
  );

  static TextStyle get timerDisplaySmall => const TextStyle(
    fontFamily: 'Lora',
    package: _designPackage,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
  );

  static TextStyle get statValue => const TextStyle(
    fontFamily: 'Lora',
    package: _designPackage,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get statLabel => const TextStyle(
    fontFamily: 'Nunito',
    package: _designPackage,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}
