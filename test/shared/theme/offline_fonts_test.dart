import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/shared/theme/app_theme.dart';
import 'package:sundial/shared/theme/app_text_styles.dart';

/// Sundial is local-first: fonts must be BUNDLED (assets/fonts/) and referenced
/// by family, never fetched from fonts.gstatic.com at runtime. google_fonts set
/// the family to a variant name like 'Lora_regular' and would fetch the .ttf
/// from Google on first use — a data egress on launch. A plain bundled family
/// is exactly 'Lora'/'Nunito'. These assertions lock out a regression back to
/// runtime font egress.
void main() {
  test('text theme uses bundled Lora/Nunito families (no runtime fetch)', () {
    final t = AppTheme.light.textTheme;
    expect(t.displayLarge!.fontFamily, 'Lora');
    expect(t.headlineMedium!.fontFamily, 'Lora');
    expect(t.titleLarge!.fontFamily, 'Nunito');
    expect(t.bodyMedium!.fontFamily, 'Nunito');
  });

  test('dark theme also uses the bundled families', () {
    final t = AppTheme.dark.textTheme;
    expect(t.displaySmall!.fontFamily, 'Lora');
    expect(t.bodySmall!.fontFamily, 'Nunito');
  });

  test('app text styles use bundled families', () {
    expect(AppTextStyles.timerDisplay.fontFamily, 'Lora');
    expect(AppTextStyles.statValue.fontFamily, 'Lora');
    expect(AppTextStyles.statLabel.fontFamily, 'Nunito');
  });
}
