import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:sundial/shared/theme/app_colors.dart';
import 'package:sundial/shared/theme/app_theme.dart';

/// Tier-T design sync: Sundial renders openhearth_design's type ladder and
/// aliases the canonical colour tokens it shares. These assertions pin the
/// exact values the goldens were approved with — if either side drifts, this
/// fails before any golden does, naming the role that moved.
const _pkg = 'openhearth_design';

void main() {
  group('typography sync', () {
    test(
        'both themes use OhTypography.materialTextTheme, the 0.7.0 ladder the '
        'goldens were rendered with', () {
      // The canonical ladder as of openhearth_design 0.7.0 (one ~1.2 ladder:
      // 13/16/19/23/28/33/40/48/57), family+size+weight only. Spelled out
      // per-role so a drift names the role that moved and forces a golden
      // re-approval rather than slipping in unseen. Since 0.7.2 the families
      // are openhearth_design's own package fonts (Sundial no longer bundles
      // its own Lora/Nunito copy): `package:` must be set here too, or the
      // TextStyle's internal `_package` field won't match, even though the
      // resolved `fontFamily` string looks identical when printed.
      const expected = <String, TextStyle>{
        'displayLarge': TextStyle(
            fontFamily: 'Lora',
            package: _pkg,
            fontSize: 57,
            fontWeight: FontWeight.w700),
        'displayMedium': TextStyle(
            fontFamily: 'Lora',
            package: _pkg,
            fontSize: 48,
            fontWeight: FontWeight.w700),
        'displaySmall': TextStyle(
            fontFamily: 'Lora',
            package: _pkg,
            fontSize: 40,
            fontWeight: FontWeight.w700),
        'headlineLarge': TextStyle(
            fontFamily: 'Lora',
            package: _pkg,
            fontSize: 33,
            fontWeight: FontWeight.w700),
        'headlineMedium': TextStyle(
            fontFamily: 'Lora',
            package: _pkg,
            fontSize: 28,
            fontWeight: FontWeight.w700),
        'headlineSmall': TextStyle(
            fontFamily: 'Lora',
            package: _pkg,
            fontSize: 23,
            fontWeight: FontWeight.w700),
        'titleLarge': TextStyle(
            fontFamily: 'Nunito',
            package: _pkg,
            fontSize: 19,
            fontWeight: FontWeight.w700),
        'titleMedium': TextStyle(
            fontFamily: 'Nunito',
            package: _pkg,
            fontSize: 16,
            fontWeight: FontWeight.w600),
        'titleSmall': TextStyle(
            fontFamily: 'Nunito',
            package: _pkg,
            fontSize: 13,
            fontWeight: FontWeight.w700),
        'bodyLarge':
            TextStyle(fontFamily: 'Nunito', package: _pkg, fontSize: 19),
        'bodyMedium':
            TextStyle(fontFamily: 'Nunito', package: _pkg, fontSize: 16),
        'bodySmall':
            TextStyle(fontFamily: 'Nunito', package: _pkg, fontSize: 13),
        'labelLarge': TextStyle(
            fontFamily: 'Nunito',
            package: _pkg,
            fontSize: 16,
            fontWeight: FontWeight.w600),
        'labelMedium': TextStyle(
            fontFamily: 'Nunito',
            package: _pkg,
            fontSize: 13,
            fontWeight: FontWeight.w600),
        'labelSmall': TextStyle(
            fontFamily: 'Nunito',
            package: _pkg,
            fontSize: 13,
            fontWeight: FontWeight.w500),
      };

      const canonical = OhTypography.materialTextTheme;
      final byRole = <String, TextStyle?>{
        'displayLarge': canonical.displayLarge,
        'displayMedium': canonical.displayMedium,
        'displaySmall': canonical.displaySmall,
        'headlineLarge': canonical.headlineLarge,
        'headlineMedium': canonical.headlineMedium,
        'headlineSmall': canonical.headlineSmall,
        'titleLarge': canonical.titleLarge,
        'titleMedium': canonical.titleMedium,
        'titleSmall': canonical.titleSmall,
        'bodyLarge': canonical.bodyLarge,
        'bodyMedium': canonical.bodyMedium,
        'bodySmall': canonical.bodySmall,
        'labelLarge': canonical.labelLarge,
        'labelMedium': canonical.labelMedium,
        'labelSmall': canonical.labelSmall,
      };
      for (final entry in expected.entries) {
        expect(byRole[entry.key], entry.value, reason: entry.key);
      }

      // And both built themes must render exactly that ladder. ThemeData
      // merges the input TextTheme with Material defaults (colors, debug
      // labels), so compare the render-relevant fields the ladder sets.
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final t = theme.textTheme;
        final themed = <String, TextStyle?>{
          'displayLarge': t.displayLarge,
          'displayMedium': t.displayMedium,
          'displaySmall': t.displaySmall,
          'headlineLarge': t.headlineLarge,
          'headlineMedium': t.headlineMedium,
          'headlineSmall': t.headlineSmall,
          'titleLarge': t.titleLarge,
          'titleMedium': t.titleMedium,
          'titleSmall': t.titleSmall,
          'bodyLarge': t.bodyLarge,
          'bodyMedium': t.bodyMedium,
          'bodySmall': t.bodySmall,
          'labelLarge': t.labelLarge,
          'labelMedium': t.labelMedium,
          'labelSmall': t.labelSmall,
        };
        for (final entry in expected.entries) {
          final actual = themed[entry.key]!;
          expect(actual.fontFamily, entry.value.fontFamily,
              reason: entry.key);
          expect(actual.fontSize, entry.value.fontSize, reason: entry.key);
          expect(actual.fontWeight, entry.value.fontWeight, reason: entry.key);
        }
      }
    });
  });

  group('color sync', () {
    test('canonical-valued Sundial colors alias OhColors exactly', () {
      // Aliases must carry the exact ARGB the goldens were rendered with.
      expect(AppColors.sage500, const Color(0xFF5E9478));
      expect(AppColors.sage500, OhColors.sage500);
      expect(AppColors.onPace, OhColors.sage500);
      expect(AppColors.linen50, const Color(0xFFFBF8F4));
      expect(AppColors.linen50, OhColors.linen50);
      expect(AppColors.linen900, const Color(0xFF2C1810));
      expect(AppColors.linen900, OhColors.linen900);
      expect(AppColors.warmDark, const Color(0xFF1C1007));
      expect(AppColors.warmDark, OhColors.darkSurfaceBase);
    });

    test('deliberately-divergent Sundial colors stay Sundial-local', () {
      // These are close to — but NOT — canonical values; keeping them local is
      // intentional (zero visual change). Guard against a well-meant "unify".
      expect(AppColors.sage600, const Color(0xFF4E7D65));
      expect(AppColors.sage600, isNot(OhColors.sage600));
      expect(AppColors.linen100, const Color(0xFFF5F0E8));
      expect(AppColors.linen100, isNot(OhColors.linen100));
      expect(AppColors.linen200, const Color(0xFFEBE3D4));
      expect(AppColors.linen200, isNot(OhColors.linen200));
      expect(AppColors.linen700, const Color(0xFF7C6C55));
      expect(AppColors.linen700, isNot(OhColors.linen700));
      expect(AppColors.warmDark2, const Color(0xFF241508));
      expect(AppColors.warmDark2, isNot(OhColors.darkSurfaceCard));
    });
  });
}
