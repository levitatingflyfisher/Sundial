import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/stats/domain/pace.dart';

/// badass-06: progress was coloured on fraction-of-goal with no date term, so
/// a household exactly on pace was amber until August. Pace is now computed:
/// expected-to-date = goal x (day of period / days in period), today counted.
/// Forgiving by construction: within one day's share counts as on pace, and
/// within a week's share is only "slightly behind".
void main() {
  Duration h(num hours) => Duration(seconds: (hours * 3600).round());

  group('yearPace expected-to-date', () {
    test('1 January expects one day of the goal', () {
      final p = yearPace(done: Duration.zero, goalHours: 365,
          now: DateTime(2026, 1, 1, 8));
      expect(p.expected, h(1));
      expect(p.status, PaceStatus.onPace,
          reason: 'nothing logged yet on the first morning is not behind');
    });

    test('31 December expects the whole goal', () {
      final p = yearPace(
          done: h(1000), goalHours: 1000, now: DateTime(2026, 12, 31, 23));
      expect(p.expected, h(1000));
      expect(p.status, PaceStatus.onPace);
    });

    test('leap year divides by 366', () {
      final p = yearPace(
          done: Duration.zero, goalHours: 366, now: DateTime(2028, 12, 31));
      expect(p.expected, h(366));
      final feb29 = yearPace(
          done: Duration.zero, goalHours: 366, now: DateTime(2028, 2, 29));
      expect(feb29.expected, h(60));
    });
  });

  group('status is pace, not fraction of the year goal', () {
    // 30 June 2026 is day 181 of 365: expected 181/365 x 1000 = 495.9h.
    final june30 = DateTime(2026, 6, 30, 12);

    test('exactly on pace mid-year is on pace (was amber)', () {
      final exact = yearPace(done: h(1000 * 181 / 365), goalHours: 1000,
          now: june30);
      expect(exact.status, PaceStatus.onPace);
      expect(exact.phrase, 'On pace');
    });

    test('ahead by more than a day reads ahead, in words', () {
      final p = yearPace(done: h(520), goalHours: 1000, now: june30);
      expect(p.status, PaceStatus.onPace);
      expect(p.phrase, '24h 6m ahead of pace');
    });

    test('behind by under a week of goal is slightly behind', () {
      // A day's share is 1000/365 = 2.74h; a week's is 19.2h.
      final p = yearPace(done: h(486), goalHours: 1000, now: june30);
      expect(p.status, PaceStatus.slightlyBehind);
      expect(p.phrase, '9h 53m behind pace');
    });

    test('behind by more than a week of goal is behind', () {
      final p = yearPace(done: h(400), goalHours: 1000, now: june30);
      expect(p.status, PaceStatus.behind);
      expect(p.phrase, '95h 53m behind pace');
    });

    test('the summary states the expected hours to date', () {
      final p = yearPace(done: h(400), goalHours: 1000, now: june30);
      expect(p.expectedLine, '495h 53m expected by today');
    });
  });

  test('monthPace uses the days of the current month', () {
    // 15 February 2026 of 28 days, goal 28h: expected 15h.
    final p = monthPace(
        done: h(15), goalHours: 28, now: DateTime(2026, 2, 15, 20));
    expect(p.expected, h(15));
    expect(p.status, PaceStatus.onPace);
  });
}
