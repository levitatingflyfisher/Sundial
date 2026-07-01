import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/shared/extensions/datetime_ext.dart';

/// startOfWeek must be DST-safe the same way daysBetweenDates already is:
/// calendar arithmetic, never Duration subtraction from local midnight.
/// A transition inside the week (an extra or missing hour between Monday
/// midnight and the queried day's midnight) makes a 24h-per-day walk land
/// beside Monday midnight instead of on it.
void main() {
  test(
      'startOfWeek returns Monday MIDNIGHT across a mid-week DST fall-back '
      '(pinned via a child process, TZ=America/Santiago)', () async {
    // In-process the VM's timezone is fixed at startup (the CI suite runs
    // under TZ=America/Denver, whose 02:00-Sunday rule never puts the
    // transition between two midnights of the same Mon..Sun week), so the
    // discriminating case runs as a child `dart` process pinned to a zone
    // whose transition falls at midnight mid-week: America/Santiago, where
    // Saturday 2026-04-04 has 25 hours.
    final result = await Process.run(
      'dart',
      ['run', 'test/shared/extensions/start_of_week_dst_probe.dart'],
      environment: {'TZ': 'America/Santiago'},
    );
    expect(result.exitCode, 0,
        reason: 'probe failed to run:\n${result.stdout}\n${result.stderr}');
    final match = RegExp('startOfWeek=(.*)')
        .firstMatch(result.stdout as String);
    expect(match, isNotNull,
        reason: 'probe printed no result:\n${result.stdout}');
    expect(match!.group(1), '2026-03-30T00:00:00.000',
        reason: 'Sunday 2026-04-05 lies in the week of Monday 2026-03-30; '
            'startOfWeek must be that Monday at exactly local midnight');
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('startOfWeek is always a midnight and agrees with calendar '
      'construction (whole-year sweep, host TZ)', () {
    for (var d = DateTime(2026, 1, 1);
        d.year == 2026;
        d = DateTime(d.year, d.month, d.day + 1)) {
      final sow = DateTime(d.year, d.month, d.day, 12).startOfWeek;
      expect(sow.weekday, DateTime.monday, reason: 'for $d');
      expect(sow.hour, 0, reason: 'for $d');
      expect(sow.minute, 0, reason: 'for $d');
      expect(sow, DateTime(d.year, d.month, d.day - (d.weekday - 1)),
          reason: 'for $d');
    }
  });
}
