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

    test('dateOnly drops the time component to local midnight', () {
      final dt = DateTime(2026, 3, 28, 14, 30, 45, 123);
      expect(dt.dateOnly, DateTime(2026, 3, 28));
    });

    test('dateOnly is idempotent on a midnight value', () {
      final dt = DateTime(2026, 3, 28);
      expect(dt.dateOnly, dt);
    });

    test('startOfWeek returns the date-only Monday of the week', () {
      // 2026-03-28 is a Saturday; its week's Monday is 2026-03-23.
      expect(DateTime(2026, 3, 28, 9, 15).startOfWeek, DateTime(2026, 3, 23));
      // A Monday maps to itself (date-only).
      expect(DateTime(2026, 3, 23, 22).startOfWeek, DateTime(2026, 3, 23));
      // A Sunday belongs to the week started 6 days earlier.
      expect(DateTime(2026, 3, 29).startOfWeek, DateTime(2026, 3, 23));
    });

    test('startOfWeek crosses a month boundary backwards', () {
      // 2026-04-01 is a Wednesday; Monday is 2026-03-30.
      expect(DateTime(2026, 4, 1).startOfWeek, DateTime(2026, 3, 30));
    });
  });

  group('daysBetweenDates', () {
    test('counts whole calendar days regardless of times', () {
      // Naive difference would be 6 days 2 hours → inDays truncates to 6.
      expect(
        daysBetweenDates(
          DateTime(2026, 3, 1, 22),
          DateTime(2026, 3, 8, 0, 30),
        ),
        7,
      );
    });

    test('is signed: negative when b precedes a', () {
      expect(daysBetweenDates(DateTime(2026, 3, 8), DateTime(2026, 3, 1)), -7);
    });

    test('same calendar day is zero even with different times', () {
      expect(
        daysBetweenDates(DateTime(2026, 3, 8, 1), DateTime(2026, 3, 8, 23)),
        0,
      );
    });

    test('spans a DST-transition week without dropping a day', () {
      // US spring-forward 2026 is Mar 8; a 23h "day" would make the naive
      // local difference 167h → 6 days. UTC-midnight reduction keeps it 7.
      expect(
        daysBetweenDates(DateTime(2026, 3, 7, 12), DateTime(2026, 3, 14, 11)),
        7,
      );
    });
  });
}
