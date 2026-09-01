// lib/features/stats/domain/pace.dart
import 'package:sundial/shared/extensions/duration_ext.dart';

/// How a period's time outside compares with an even spread of its goal.
enum PaceStatus { onPace, slightlyBehind, behind }

/// Where a household stands against its goal *to date*, not against the
/// whole period's goal (badass-06: colouring on fraction-of-goal painted an
/// exactly-on-pace family amber until August).
///
/// Expected-to-date is goal x (day of period / days in period), counting
/// today as a whole day. Forgiveness over prevention: being short by up to
/// one day's share still reads as on pace, and up to a week's share is only
/// "slightly behind". Behind is amber in the UI, never red (VISION §3).
class Pace {
  const Pace({
    required this.done,
    required this.expected,
    required this.dayShare,
  });

  final Duration done;
  final Duration expected;

  /// The goal divided evenly over the period's days.
  final Duration dayShare;

  Duration get _gap => done - expected;

  PaceStatus get status {
    final behindBy = -_gap;
    if (behindBy <= dayShare) return PaceStatus.onPace;
    if (behindBy <= dayShare * 7) return PaceStatus.slightlyBehind;
    return PaceStatus.behind;
  }

  /// "On pace", "24h 6m ahead of pace" or "9h 53m behind pace".
  String get phrase {
    final gap = _gap;
    if (gap.abs() <= dayShare) return 'On pace';
    final amount = gap.abs().toHoursLabel();
    return gap.isNegative ? '$amount behind pace' : '$amount ahead of pace';
  }

  /// "495h 53m expected by today".
  String get expectedLine => '${expected.toHoursLabel()} expected by today';
}

int _dayIndex(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

Pace _pace(Duration done, int goalHours, int dayOfPeriod, int daysInPeriod) {
  final goalSecs = goalHours * 3600;
  return Pace(
    done: done,
    expected: Duration(seconds: (goalSecs * dayOfPeriod / daysInPeriod).round()),
    dayShare: Duration(seconds: (goalSecs / daysInPeriod).round()),
  );
}

/// Pace against an annual goal on [now]'s calendar year (leap years count).
Pace yearPace({
  required Duration done,
  required int goalHours,
  required DateTime now,
}) {
  final start = _dayIndex(DateTime(now.year));
  final days = _dayIndex(DateTime(now.year + 1)) - start;
  return _pace(done, goalHours, _dayIndex(now) - start + 1, days);
}

/// Pace against a monthly goal on [now]'s calendar month.
Pace monthPace({
  required Duration done,
  required int goalHours,
  required DateTime now,
}) {
  final days = DateTime(now.year, now.month + 1, 0).day;
  return _pace(done, goalHours, now.day, days);
}
