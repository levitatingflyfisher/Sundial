import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/flow_mode/presentation/flow_screen.dart';
import 'package:sundial/features/timer/domain/timer_state.dart';
import 'package:sundial/features/timer/presentation/timer_notifier.dart';
import 'package:sundial/features/timer/presentation/timer_screen.dart';

/// checklist-02 said the "Review & Save / Discard" screen was orphaned. It is
/// not quite: TimerStopped is where a timer lands when auto-stop's save
/// fails (confirmSession keeps the draft rather than lose it), and nothing
/// else says so. The panel now tells the truth for that case: the session is
/// not saved yet, what it holds, Save to retry, and a Discard that offers an
/// Undo which does not expire (fleet delete ruling). One widget, used by
/// both Timer and Flow.
void main() {
  for (final entry in <String, Widget>{
    'Timer': const TimerScreen(),
    'Flow': const FlowScreen(),
  }.entries) {
    testWidgets('${entry.key}: unsaved draft reads back, Discard has Undo',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.binding.setSurfaceSize(const Size(600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appDatabaseProvider
              .overrideWith((_) => AppDatabase(NativeDatabase.memory())),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(home: entry.value),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      final container = ProviderScope.containerOf(
          tester.element(find.byWidget(entry.value)));
      final notifier = container.read(timerNotifierProvider.notifier);
      await tester.runAsync(() async {
        await notifier.start();
        await notifier.buildDraftSession();
      });
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('This session isn’t saved yet'), findsOneWidget);
      expect(find.textContaining('0m · today'), findsOneWidget,
          reason: 'the draft is read back before anything is decided');
      expect(find.text('Save session'), findsOneWidget);
      expect(find.text('Review & Save'), findsNothing);

      await tester.tap(find.text('Discard'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(timerNotifierProvider), isA<TimerIdle>());
      expect(find.text('Undo'), findsOneWidget);

      await tester.pump(const Duration(minutes: 5));
      expect(find.text('Undo'), findsOneWidget, reason: 'no timer on Undo');

      await tester.tap(find.text('Undo'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(timerNotifierProvider), isA<TimerStopped>());
      expect(find.text('This session isn’t saved yet'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    });
  }
}
