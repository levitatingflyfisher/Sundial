import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/flow_mode/presentation/flow_screen.dart';
import 'package:sundial/features/stats/presentation/stats_screen.dart';
import 'package:sundial/features/timer/presentation/timer_screen.dart';
import 'package:sundial/shared/theme/app_colors.dart';

/// VISION §3 says behind pace is amber, never red. This pins that the colour
/// follows pace (actual against expected-to-date), not fraction of the year
/// goal: a household exactly on pace on 30 June is painted on-pace, and every
/// screen that shows the year says where it stands in words.
void main() {
  final june30 = DateTime(2026, 6, 30, 12);

  Future<AppDatabase> seed(int secs) async {
    final db = AppDatabase(NativeDatabase.memory());
    final start = DateTime(2026, 6, 30, 9);
    await db.into(db.sessions).insert(SessionsCompanion.insert(
          id: 's',
          startTime: start.millisecondsSinceEpoch,
          endTime: start.millisecondsSinceEpoch + secs * 1000,
          durationSecs: secs,
          dateDay: '2026-06-30',
          profileId: const Value(null),
          createdAt: 0,
          updatedAt: 0,
        ));
    return db;
  }

  Future<void> pump(WidgetTester tester, AppDatabase db, Widget screen) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(600, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((_) => db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(home: Scaffold(body: screen)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  }

  Finder yearBar() => find.descendant(
        of: find.ancestor(
            of: find.text('This Year'), matching: find.byType(Card)),
        matching: find.byType(LinearProgressIndicator),
      );

  // 181/365 of 1000h, to the second.
  const onPaceSecs = 1785205;

  testWidgets('Stats: exactly on pace on 30 June is on-pace, not amber',
      (tester) async {
    final db = await seed(onPaceSecs);
    await withClock(Clock.fixed(june30), () async {
      await pump(tester, db, const StatsScreen());
      final bar = tester.widget<LinearProgressIndicator>(yearBar());
      expect(bar.color, AppColors.onPace);
      expect(find.textContaining('On pace'), findsOneWidget);
      expect(find.textContaining('495h 53m expected by today'),
          findsOneWidget);
    });
    await drain(tester);
  });

  testWidgets('Stats: well behind pace is amber and says by how much',
      (tester) async {
    final db = await seed(400 * 3600);
    await withClock(Clock.fixed(june30), () async {
      await pump(tester, db, const StatsScreen());
      final bar = tester.widget<LinearProgressIndicator>(yearBar());
      expect(bar.color, AppColors.behind);
      expect(find.textContaining('95h 53m behind pace'), findsOneWidget);
    });
    await drain(tester);
  });

  testWidgets('Timer and Flow say where the year stands', (tester) async {
    final db = await seed(400 * 3600);
    await withClock(Clock.fixed(june30), () async {
      await pump(tester, db, const TimerScreen());
      expect(find.textContaining('95h 53m behind pace'), findsOneWidget);
      await pump(tester, db, const FlowScreen());
      expect(find.textContaining('95h 53m behind pace'), findsOneWidget);
    });
    await drain(tester);
  });
}
