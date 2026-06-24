import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/timer/presentation/timer_screen.dart';

Future<Widget> makeTimerApp() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((_) => AppDatabase(NativeDatabase.memory())),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const MaterialApp(home: TimerScreen()),
  );
}

void main() {
  testWidgets('TimerScreen shows START button when idle', (tester) async {
    await tester.pumpWidget(await makeTimerApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('START'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    // Drain any pending Drift stream timers before teardown.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  testWidgets('Tapping START changes to STOP + PAUSE', (tester) async {
    await tester.pumpWidget(await makeTimerApp());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('START'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('STOP'), findsOneWidget);
    expect(find.text('PAUSE'), findsOneWidget);
    // Drain any pending Drift stream timers before teardown.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
