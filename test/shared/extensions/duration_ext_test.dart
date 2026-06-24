import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/shared/extensions/duration_ext.dart';

void main() {
  group('DurationExt', () {
    test('toHhMm formats under 1 hour', () {
      expect(const Duration(minutes: 34, seconds: 12).toHhMm(), '34:12');
    });

    test('toHhMm formats over 1 hour', () {
      expect(const Duration(hours: 2, minutes: 5, seconds: 9).toHhMm(), '2:05:09');
    });

    test('toHoursLabel returns singular', () {
      expect(const Duration(hours: 1, minutes: 0).toHoursLabel(), '1h');
    });

    test('toHoursLabel returns hours and minutes', () {
      expect(const Duration(hours: 2, minutes: 34).toHoursLabel(), '2h 34m');
    });

    test('toHoursLabel returns minutes only under 1 hour', () {
      expect(const Duration(minutes: 45).toHoursLabel(), '45m');
    });
  });
}
