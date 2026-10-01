import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oh_fleet_conformance/oh_fleet_conformance.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/flow_mode/presentation/flow_screen.dart';
import 'package:sundial/features/sessions/presentation/history_screen.dart';
import 'package:sundial/features/sessions/presentation/manual_entry_sheet.dart';
import 'package:sundial/features/timer/presentation/timer_screen.dart';
import 'package:sundial/shared/theme/app_theme.dart';

/// Release gate (roadmap item 24): at 360dp × 1.3 text each primary screen's
/// main action is on screen and tappable (scrolling to it is fine), then the
/// same screen survives 320dp × 3.0 without overflowing. Rendered with the
/// app's real theme, so the 0.7.0 type ladder (body 16) is what is measured.
void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
  });

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await db.close();
  }

  Widget app(Widget screen) => ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(theme: AppTheme.light, home: screen),
      );

  testWidgets('TimerScreen: START reachable at 360dp x 1.3', (tester) async {
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () => tester.pumpWidget(app(const TimerScreen())),
      primaryAction: find.text('START'),
    );
    await drain(tester);
  });

  testWidgets('FlowScreen: START reachable at 360dp x 1.3', (tester) async {
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () => tester.pumpWidget(app(const FlowScreen())),
      primaryAction: find.text('START'),
    );
    await drain(tester);
  });

  testWidgets('ManualEntrySheet: Save reachable at 360dp x 1.3',
      (tester) async {
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () => tester.pumpWidget(app(const ManualEntrySheet())),
      primaryAction: find.text('Save'),
    );
    await drain(tester);
  });

  /// A month with long days in it: the calendar's day cells carry a duration
  /// label under the date, which is what overflowed at large text.
  Future<void> seedMonth() async {
    final now = DateTime.now();
    for (final day in [1, 2, 3, 9, 10, 17, 24, 28]) {
      final start = DateTime(now.year, now.month, day, 9);
      final key = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${day.toString().padLeft(2, '0')}';
      await db.into(db.sessions).insert(SessionsCompanion.insert(
            id: 's$day',
            startTime: start.millisecondsSinceEpoch,
            endTime: start.add(const Duration(hours: 13, minutes: 45))
                .millisecondsSinceEpoch,
            durationSecs: 13 * 3600 + 45 * 60,
            dateDay: key,
            createdAt: start.millisecondsSinceEpoch,
            updatedAt: start.millisecondsSinceEpoch,
          ));
    }
  }

  // History was in no sweep, and its calendar's fixed 48 px day cells
  // overflowed at 320dp from 2x text (batch 1's new finding).
  testWidgets('HistoryScreen: the view switch reachable at 360dp x 1.3',
      (tester) async {
    await tester.runAsync(seedMonth);
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () => tester.pumpWidget(app(const HistoryScreen())),
      primaryAction: find.text('List'),
    );
    await drain(tester);
  });

  testWidgets('HistoryScreen: the calendar holds at 320dp x 2.0 to 3.0',
      (tester) async {
    await tester.runAsync(seedMonth);
    await runA11ySweep(
      tester,
      textScales: const [2.0, 2.5, 3.0],
      pumpScreen: () => tester.pumpWidget(app(const HistoryScreen())),
    );
    await drain(tester);
  });
}
