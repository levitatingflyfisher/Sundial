import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:oh_fleet_conformance/src/color_science.dart';
import 'package:sundial/shared/theme/app_colors.dart';

/// dashboard-09: AppColors.behind and sunGold were the same hex, so "you
/// are behind" and "you earned this" shared a colour. Badge gold now has
/// its own value, at least as far from both pace warnings as C12 asks of
/// an accent and the error red (CIEDE2000 >= 12).
void main() {
  double de(int a, int b) => ciede2000(labFromArgb(a), labFromArgb(b));

  test('badge gold is told apart from both behind-pace colours', () {
    expect(de(AppColors.sunGold.toARGB32(), AppColors.behind.toARGB32()),
        greaterThanOrEqualTo(12));
    expect(
        de(AppColors.sunGold.toARGB32(), AppColors.slightlyBehind.toARGB32()),
        greaterThanOrEqualTo(12));
  });

  test('earned badges use AppColors.sunGold, not a retyped hex', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.endsWith('app_colors.dart')) continue;
      if (f.readAsStringSync().contains('0xFFF5A623')) offenders.add(f.path);
    }
    expect(offenders, isEmpty);
  });
}
