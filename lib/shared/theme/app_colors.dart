import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';

/// Sundial palette. Values that coincide with the fleet-canonical OhColors
/// tokens are ALIASED to them (never retyped); the rest are deliberately
/// Sundial-local — some sit close to canonical neighbours but are not equal,
/// and unifying them would be a visual change. Both sets are locked by
/// test/shared/theme/design_sync_test.dart.
class AppColors {
  AppColors._();

  // Sage — Sundial primary (sage500 is the canonical token; 600/700 are
  // Sundial's own darker ramp, ≠ OhColors.sage600)
  static const sage500 = OhColors.sage500;
  static const sage600 = Color(0xFF4E7D65);
  static const sage700 = Color(0xFF3D6652);

  // Linen — neutral ground (50/900 canonical; 100/200/700 Sundial-local)
  static const linen50  = OhColors.linen50;
  static const linen100 = Color(0xFFF5F0E8);
  static const linen200 = Color(0xFFEBE3D4);
  static const linen700 = Color(0xFF7C6C55);
  static const linen900 = OhColors.linen900;

  // Progress (never red — yellow/orange when behind)
  static const onPace         = OhColors.sage500;
  static const slightlyBehind = Color(0xFFF5C842);
  static const behind         = Color(0xFFF5A623);

  // Warm dark surfaces (base is canonical; warmDark2 ≠ OhColors.darkSurfaceCard)
  static const warmDark  = OhColors.darkSurfaceBase;
  static const warmDark2 = Color(0xFF241508);

  // Badge + accent
  static const sunGold = Color(0xFFF5A623);
}
