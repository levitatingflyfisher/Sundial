import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/router/app_shell.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';
import 'package:sundial/features/timer/domain/timer_state.dart';
import 'package:sundial/features/timer/presentation/timer_notifier.dart';
import 'package:sundial/features/timer/presentation/timer_screen.dart';

/// A running, paused or unsaved session must survive leaving the Timer tab
/// and an app restart. The unsaved draft (an auto-stop whose save failed)
/// used to live only in an auto-dispose provider's memory: switching tabs
/// disposed it and the session was gone.
void main() {
  late SharedPreferences prefs;
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
  });

  ProviderContainer container() {
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWith((_) => db),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('restart (a fresh container over the same stored state)', () {
    test('an unsaved draft is offered back', () async {
      final before = container();
      final notifier = before.read(timerNotifierProvider.notifier);
      await notifier.start();
      final draft = await notifier.buildDraftSession();
      before.dispose();

      final after = container();
      final state = after.read(timerNotifierProvider);
      expect(state, isA<TimerStopped>());
      final kept = (state as TimerStopped).session;
      expect(kept.id, draft.id);
      expect(kept.durationSecs, draft.durationSecs);
      expect(kept.startTime, draft.startTime);
    });

    test('a saved draft is not offered again', () async {
      final before = container();
      final notifier = before.read(timerNotifierProvider.notifier);
      await notifier.start();
      final draft = await notifier.buildDraftSession();
      await notifier.confirmSession(draft);
      before.dispose();

      expect(container().read(timerNotifierProvider), isA<TimerIdle>());
    });

    test('a discarded draft stays discarded; Undo brings it back for good',
        () async {
      final before = container();
      final notifier = before.read(timerNotifierProvider.notifier);
      await notifier.start();
      final draft = await notifier.buildDraftSession();
      notifier.discard();
      before.dispose();
      final middle = container();
      expect(middle.read(timerNotifierProvider), isA<TimerIdle>());

      middle.read(timerNotifierProvider.notifier).restoreDiscarded(draft);
      middle.dispose();
      expect(container().read(timerNotifierProvider), isA<TimerStopped>());
    });

    test('a running timer comes back running', () async {
      final before = container();
      await before.read(timerNotifierProvider.notifier).start();
      before.dispose();
      expect(container().read(timerNotifierProvider), isA<TimerRunning>());
    });
  });

  testWidgets('Rich mode: leave the Timer tab and come back, draft intact',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(initialLocation: '/timer', routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/timer', builder: (_, __) => const TimerScreen()),
          GoRoute(
              path: '/history',
              builder: (_, __) => const Center(child: Text('history tab'))),
        ],
      ),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((_) => db),
        appModeProvider.overrideWith((_) => Stream.value(AppMode.rich)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    final c =
        ProviderScope.containerOf(tester.element(find.byType(TimerScreen)));
    final notifier = c.read(timerNotifierProvider.notifier);
    await tester.runAsync(() async {
      await notifier.start();
      await notifier.buildDraftSession();
    });
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('This session isn’t saved yet'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('history tab'), findsOneWidget);
    expect(find.byType(TimerScreen), findsNothing,
        reason: 'the Timer tab really left the tree');
    await tester.tap(find.text('Timer'));
    await tester.pumpAndSettle();

    expect(find.text('This session isn’t saved yet'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
