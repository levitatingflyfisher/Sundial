import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get timerDisplay => GoogleFonts.lora(
    fontSize: 56,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
  );

  static TextStyle get timerDisplaySmall => GoogleFonts.lora(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
  );

  static TextStyle get statValue => GoogleFonts.lora(
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get statLabel => GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}
