import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oh_fleet_conformance/oh_fleet_conformance.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/flow_mode/presentation/flow_screen.dart';
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
}
