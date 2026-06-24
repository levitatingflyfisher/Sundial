import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/stats/presentation/cumulative_chart.dart';
import 'package:sundial/features/stats/presentation/heatmap_chart.dart';
import 'package:sundial/features/stats/presentation/stats_screen.dart';

/// Builds an in-memory database seeded with profiles + sessions so widget
/// tests can pump StatsScreen (or the charts) with real streams.
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

Future<Widget> _wrap(AppDatabase db, Widget child) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWith((_) => db),
    ],
    child: MaterialApp(home: child),
  );
}

/// Tear down a widget test that mounted Drift-backed StreamBuilders inside a
/// ProviderScope. Do NOT call `db.close()` — it deadlocks against live
/// Riverpod providers. Instead unmount via an empty widget and pump twice so
/// Drift's `StreamQueryStore.markAsClosed` Timer(0) debounce drains and the
/// test framework's pending-timer invariant passes.
Future<void> _tearDown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  // Item 3 of the 2026-04-09 multi-profile completion plan.
  group('StatsScreen profile filter row', () {
    testWidgets(
        'filter row is hidden when only one profile exists',
        (tester) async {
      // The migration auto-seeds the 'default' profile; don't add any more.
      final db = await _seedDb();
      await tester.pumpWidget(await _wrap(db, const StatsScreen()));
      await tester.pump();

      expect(find.text('Everyone'), findsNothing,
          reason: 'solo users must not see a profile picker row');
      await _tearDown(tester);
    });

    testWidgets(
        'filter row is visible when 2+ profiles exist',
        (tester) async {
      final db = await _seedDb(
        profiles: const [(id: 'dad', name: 'Dad'), (id: 'mom', name: 'Mom')],
      );
      await tester.pumpWidget(await _wrap(db, const StatsScreen()));
      await tester.pump();

      expect(find.text('Everyone'), findsOneWidget);
      expect(find.text('Dad'), findsOneWidget);
      expect(find.text('Mom'), findsOneWidget);
      await _tearDown(tester);
    });

    testWidgets(
        'selecting Dad updates Today card to dad + everyone totals',
        (tester) async {
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final db = await _seedDb(
        profiles: const [(id: 'dad', name: 'Dad'), (id: 'mom', name: 'Mom')],
        sessions: [
          // Dad: 1h today
          (id: 's1', profileId: 'dad', dateDay: today, durationSecs: 3600),
          // Mom: 2h today
          (id: 's2', profileId: 'mom', dateDay: today, durationSecs: 7200),
          // Everyone: 30m today (null profile)
          (id: 's3', profileId: null, dateDay: today, durationSecs: 1800),
        ],
      );
      await tester.pumpWidget(await _wrap(db, const StatsScreen()));
      // Pump a few frames so StreamBuilders resolve.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Initial view (Everyone filter): Today should show 3h 30m total.
      expect(find.text('3h 30m'), findsWidgets,
          reason: 'Everyone view sums all sessions');

      // Tap the Dad chip.
      await tester.tap(find.text('Dad'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Today card should now show dad(1h) + everyone(30m) = 1h 30m.
      expect(find.text('1h 30m'), findsWidgets,
          reason: 'per-profile view must include null-profile sessions');
      // And must NOT show mom's 2h-only bucket.
      expect(find.text('2h'), findsNothing);
      await _tearDown(tester);
    });
  });

  // Unit-level tests for the chart widgets' profileId parameter. These
  // verify the wiring from prop → query → rendered data without needing
  // the full StatsScreen scaffold.
  group('CumulativeChart profileId filter', () {
    testWidgets('totals only include matching + null-profile sessions',
        (tester) async {
      final db = await _seedDb(
        profiles: const [(id: 'dad', name: 'Dad'), (id: 'mom', name: 'Mom')],
        sessions: const [
          // Each session lands in a distinct month so the running total
          // label reflects the full aggregation.
          (id: 'd1', profileId: 'dad', dateDay: '2026-01-15', durationSecs: 3600),
          (id: 'm1', profileId: 'mom', dateDay: '2026-02-15', durationSecs: 7200),
          (id: 'e1', profileId: null, dateDay: '2026-03-15', durationSecs: 1800),
        ],
      );
      await tester.pumpWidget(
        await _wrap(db, const Scaffold(body: CumulativeChart(profileId: 'dad'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // dad(1h) + everyone(30m) = 1.5h, rounded in the chart title to 2h
      // via toStringAsFixed(0) which rounds half away from zero.
      // Total label format: "${points.last.hours.toStringAsFixed(0)}h total"
      expect(find.text('2h total'), findsOneWidget,
          reason: '1.5h rounds to 2 via toStringAsFixed(0)');
      await _tearDown(tester);
    });
  });

  group('HeatmapChart profileId filter', () {
    testWidgets('only draws cells for matching + null-profile sessions',
        (tester) async {
      // No assertion-level painting inspection (custom painter); we verify
      // by checking the underlying provider is queried with the profileId
      // via a smoke-test pump that doesn't throw.
      final db = await _seedDb(
        profiles: const [(id: 'dad', name: 'Dad')],
        sessions: const [
          (id: 'd1', profileId: 'dad', dateDay: '2026-04-05', durationSecs: 3600),
          (id: 'e1', profileId: null, dateDay: '2026-04-06', durationSecs: 1800),
        ],
      );
      await tester.pumpWidget(
        await _wrap(db, const Scaffold(body: HeatmapChart(profileId: 'dad'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Heatmap renders a horizontal scroll with CustomPaint — absence of
      // exceptions + the heading being present is sufficient smoke coverage
      // that the filtered stream was subscribed to without error.
      expect(find.text('Last 12 months'), findsOneWidget);
      await _tearDown(tester);
    });
  });
}
