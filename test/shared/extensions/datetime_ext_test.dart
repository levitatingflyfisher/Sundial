import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/shared/extensions/datetime_ext.dart';

void main() {
  group('DateTimeExt', () {
    test('toDateDay returns YYYY-MM-DD', () {
      final dt = DateTime(2026, 3, 28, 14, 30);
      expect(dt.toDateDay(), '2026-03-28');
    });

    test('toYearMonth returns YYYY-MM', () {
      final dt = DateTime(2026, 3, 28);
      expect(dt.toYearMonth(), '2026-03');
    });

    test('toYear returns YYYY', () {
      final dt = DateTime(2026, 3, 28);
      expect(dt.toYear(), '2026');
    });
  });
}
