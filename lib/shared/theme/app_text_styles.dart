import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get timerDisplay => const TextStyle(
    fontFamily: 'Lora',
    fontSize: 56,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
  );

  static TextStyle get timerDisplaySmall => const TextStyle(
    fontFamily: 'Lora',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
  );

  static TextStyle get statValue => const TextStyle(
    fontFamily: 'Lora',
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get statLabel => const TextStyle(
    fontFamily: 'Nunito',
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}
