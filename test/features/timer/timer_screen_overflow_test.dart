import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/timer/presentation/timer_screen.dart';

/// Regression guard for the narrow-width + large-accessibility-text-scale
/// layout. The visual golden sweep (test/visual/timer_screen_golden_test.dart)
/// surfaced two RenderFlex overflows on TimerScreen at 320dp × textScale 3.0:
/// the `_StatsRow` Row overflowed horizontally and the body Column overflowed
/// vertically. This test pins the worst case so the fix can't silently regress.
Future<Widget> _makeTimerApp(double textScale) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      appDatabaseProvider
          .overrideWith((_) => AppDatabase(NativeDatabase.memory())),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    // Inject the text scale via the app builder so it actually reaches the
    // screen — a MediaQuery placed above MaterialApp is ignored because the
    // app rebuilds its own from the view.
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const TimerScreen(),
    ),
  );
}

void main() {
  testWidgets(
      'TimerScreen does not overflow at 320dp width and textScale 3.0',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(await _makeTimerApp(3.0));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull,
        reason: 'no RenderFlex overflow at narrow width + large text scale');

    // Drain pending Drift stream timers before teardown.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
