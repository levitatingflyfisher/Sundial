import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/stats/presentation/stats_screen.dart';

import 'visual_golden_helper.dart';

/// Builds an in-memory database seeded with profiles + sessions — copied from
/// test/features/stats/stats_screen_test.dart so the golden renders the same
/// real Drift-backed streams the unit tests assert against.
Future<AppDatabase> _seedDb({
  List<({String id, String name})> profiles = const [],
  List<({String id, String? profileId, String dateDay, int durationSecs})>
      sessions = const [],
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  for (final p in profiles) {
    await db.into(db.profiles).insert(
          ProfilesCompanion.insert(
            id: p.id,
            name: p.name,
            colorValue: 0xFF5E9478,
            createdAt: 0,
            sortOrder: const Value(0),
          ),
        );
  }
  for (final s in sessions) {
    final parts = s.dateDay.split('-');
    final start = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
      9,
    );
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: s.id,
            startTime: start.millisecondsSinceEpoch,
            endTime: start.millisecondsSinceEpoch + s.durationSecs * 1000,
            durationSecs: s.durationSecs,
            dateDay: s.dateDay,
            profileId: Value(s.profileId),
            createdAt: start.millisecondsSinceEpoch,
            updatedAt: start.millisecondsSinceEpoch,
          ),
        );
  }
  return db;
}

/// Drain Drift-backed StreamBuilders before teardown (see the same helper in
/// stats_screen_test.dart). Do NOT call db.close(); unmount + two micro-pumps
/// lets Drift's markAsClosed Timer(0) debounce settle so the pending-timer
/// invariant passes.
Future<void> _tearDown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  testWidgets('StatsScreen responsive golden sweep', (tester) async {
    // Pin "today" — StatsScreen derives today/month/year keys, the monthly
    // breakdown, and the heatmap's today boundary from clock.now(), so an
    // unpinned render changes every real day and the golden rots. 2026-05-20
    // puts the fixed s4 session (2026-05-15) five days back: a second visible
    // heatmap day that also counts into This Month / This Year / May's bar.
    final fixedNow = DateTime(2026, 5, 20, 12);
    const today = '2026-05-20';
    // Two profiles so the filter row renders, plus a few sessions so the
    // Today/charts cards show real numbers — the layout most likely to crowd
    // at narrow widths and large text scales.
    final db = await _seedDb(
      profiles: const [(id: 'dad', name: 'Dad'), (id: 'mom', name: 'Mom')],
      sessions: [
        (id: 's1', profileId: 'dad', dateDay: today, durationSecs: 3600),
        (id: 's2', profileId: 'mom', dateDay: today, durationSecs: 7200),
        (id: 's3', profileId: null, dateDay: today, durationSecs: 1800),
        (id: 's4', profileId: 'dad', dateDay: '2026-05-15', durationSecs: 5400),
      ],
    );

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await withClock(Clock.fixed(fixedNow), () async {
      await goldenAtSizes(
        tester,
        name: 'stats_screen',
        home: ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appDatabaseProvider.overrideWith((_) => db),
          ],
          child: const StatsScreen(),
        ),
        // App theme is built via google_fonts (Lora/Nunito); bypass it with a
        // plain Roboto theme that flutter_test_config.dart loads.
        theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
        sizes: const {
          'phone': Size(360, 800),
          'narrow': Size(320, 800),
        },
        textScales: const <double>[1.0, 3.0],
      );
    });

    await _tearDown(tester);
  });
}
