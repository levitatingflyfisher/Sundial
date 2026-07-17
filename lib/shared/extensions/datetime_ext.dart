import 'package:intl/intl.dart';

extension DateTimeExt on DateTime {
  static final _dayFmt = DateFormat('yyyy-MM-dd');
  static final _monthFmt = DateFormat('yyyy-MM');
  static final _yearFmt = DateFormat('yyyy');

  String toDateDay() => _dayFmt.format(this);
  String toYearMonth() => _monthFmt.format(this);
  String toYear() => _yearFmt.format(this);

  /// Midnight of this date, dropping the time component — the canonical form
  /// for the date-only keys the check-in/pulse tables store.
  DateTime get dateOnly => DateTime(year, month, day);

  /// The date-only Monday of this date's week (Dart weekday: Mon = 1 … Sun = 7),
  /// matching the weekly aggregation the adherence/pulse logic keys on.
  DateTime get startOfWeek {
    final day = dateOnly;
    return day.subtract(Duration(days: day.weekday - 1));
  }
}

/// Whole calendar days from [a] to [b], DST-safe. Both dates are reduced to
/// their **UTC midnight** before subtracting, so a daylight-saving transition
/// between them can never add or drop the hour that would skew a naive
/// `b.difference(a).inDays` (which truncates 167h to 6, not 7). Positive when
/// [b] is the later date; the calendar day is all that matters, times are
/// ignored.
int daysBetweenDates(DateTime a, DateTime b) {
  final ua = DateTime.utc(a.year, a.month, a.day);
  final ub = DateTime.utc(b.year, b.month, b.day);
  return ub.difference(ua).inDays;
}
