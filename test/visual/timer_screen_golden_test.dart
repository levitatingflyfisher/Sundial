import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/timer/presentation/timer_screen.dart';

import 'visual_golden_helper.dart';

/// Drain Drift-backed StreamBuilders before teardown (same pattern the unit
/// test in test/features/timer/timer_screen_test.dart uses).
Future<void> _tearDown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(Duration.zero);
}

void main() {
  testWidgets('TimerScreen idle responsive golden sweep', (tester) async {
    // TimerScreen's AppTextStyles now use BUNDLED font families (no google_fonts,
    // no network fetch at build time), so no font stub is needed.

    // Mirror makeTimerApp() from timer_screen_test.dart exactly: SharedPrefs
    // mock first, then the two core provider overrides. Rendered idle so the
    // SundialFace pulse AnimationController never repeats (pumpAndSettle would
    // otherwise hang on an infinite animation).
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await goldenAtSizes(
      tester,
      name: 'timer_screen',
      home: ProviderScope(
        overrides: [
          appDatabaseProvider
              .overrideWith((_) => AppDatabase(NativeDatabase.memory())),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TimerScreen(),
      ),
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      sizes: const {
        'phone': Size(360, 800),
        'narrow': Size(320, 800),
      },
      textScales: const <double>[1.0, 3.0],
    );

    await _tearDown(tester);
  });
}
