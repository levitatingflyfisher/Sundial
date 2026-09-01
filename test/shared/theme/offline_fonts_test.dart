import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/shared/theme/app_theme.dart';
import 'package:sundial/shared/theme/app_text_styles.dart';

/// Sundial is local-first: fonts must resolve from a bundled asset, never be
/// fetched from fonts.gstatic.com at runtime. google_fonts sets the family to
/// a variant name like 'Lora_regular' and fetches the .ttf from Google on
/// first use — a data egress on launch.
///
/// Since openhearth_design 0.7.2 the bundle is that package's, not a copy
/// Sundial ships itself: a plain bundled family used to be exactly
/// 'Lora'/'Nunito', now it is the package-qualified
/// 'packages/openhearth_design/Lora'/'.../Nunito' — still a local asset, just
/// no longer this app's own file. These assertions lock out a regression
/// back to runtime font egress, and confirm the fonts openhearth_design
/// promises are actually declared and resolvable, not merely named (a
/// declared-but-missing asset fails silently at first paint, not at
/// `pub get`).
const _package = 'openhearth_design';
const _lora = 'packages/$_package/Lora';
const _nunito = 'packages/$_package/Nunito';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'text theme uses openhearth_design\'s package Lora/Nunito families '
      '(no runtime fetch)', () {
    final t = AppTheme.light.textTheme;
    expect(t.displayLarge!.fontFamily, _lora);
    expect(t.headlineMedium!.fontFamily, _lora);
    expect(t.titleLarge!.fontFamily, _nunito);
    expect(t.bodyMedium!.fontFamily, _nunito);
  });

  test('dark theme also uses the package families', () {
    final t = AppTheme.dark.textTheme;
    expect(t.displaySmall!.fontFamily, _lora);
    expect(t.bodySmall!.fontFamily, _nunito);
  });

  test('app text styles use the package families', () {
    expect(AppTextStyles.timerDisplay.fontFamily, _lora);
    expect(AppTextStyles.statValue.fontFamily, _lora);
    expect(AppTextStyles.statLabel.fontFamily, _nunito);
  });

  test(
      'openhearth_design declares Lora/Nunito as package fonts, and the '
      'assets they name actually resolve', () async {
    final manifest =
        json.decode(await rootBundle.loadString('FontManifest.json'))
            as List<dynamic>;
    final families = manifest
        .cast<Map<String, dynamic>>()
        .map((e) => e['family'] as String)
        .toSet();
    expect(families, containsAll([_lora, _nunito]),
        reason: 'openhearth_design should still declare its package fonts '
            'in the merged FontManifest');

    // Declared-but-missing would fail at first paint, not at pub get — load
    // the actual files openhearth_design ships to prove they resolve.
    for (final asset in [
      'packages/openhearth_design/fonts/Lora-Regular.ttf',
      'packages/openhearth_design/fonts/Nunito-Regular.ttf',
    ]) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.lengthInBytes, greaterThan(0), reason: asset);
    }
  });
}
