import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/timer/domain/timer_state.dart';
import 'package:sundial/features/timer/presentation/timer_notifier.dart';

ProviderContainer makeContainer({Map<String, Object> prefsValues = const {}}) {
  SharedPreferences.setMockInitialValues(prefsValues);
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith((_) {
        final db = AppDatabase(NativeDatabase.memory());
        return db;
      }),
      sharedPreferencesProvider.overrideWith(
        (ref) => throw UnimplementedError('call makeContainer with async prefs'),
      ),
    ],
  );
}

void main() {
  group('TimerNotifier', () {
    test('initial state is idle', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((_) => AppDatabase(NativeDatabase.memory())),
      ]);
      addTearDown(container.dispose);

      expect(container.read(timerNotifierProvider), isA<TimerIdle>());
    });

    test('start transitions idle → running', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((_) => AppDatabase(NativeDatabase.memory())),
      ]);
      addTearDown(container.dispose);

      await container.read(timerNotifierProvider.notifier).start();
      expect(container.read(timerNotifierProvider), isA<TimerRunning>());
    });

    test('pause transitions running → paused', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((_) => AppDatabase(NativeDatabase.memory())),
      ]);
      addTearDown(container.dispose);

      await container.read(timerNotifierProvider.notifier).start();
      await container.read(timerNotifierProvider.notifier).pause();
      expect(container.read(timerNotifierProvider), isA<TimerPaused>());
    });

    test('resume transitions paused → running', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((_) => AppDatabase(NativeDatabase.memory())),
      ]);
      addTearDown(container.dispose);

      await container.read(timerNotifierProvider.notifier).start();
      await container.read(timerNotifierProvider.notifier).pause();
      await container.read(timerNotifierProvider.notifier).resume();
      expect(container.read(timerNotifierProvider), isA<TimerRunning>());
    });

    test('stop transitions running → stopped with draft session', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((_) => AppDatabase(NativeDatabase.memory())),
      ]);
      addTearDown(container.dispose);

      await container.read(timerNotifierProvider.notifier).start();
      await container.read(timerNotifierProvider.notifier).buildDraftSession();
      expect(container.read(timerNotifierProvider), isA<TimerStopped>());
    });

    test('cold resume reconstructs running state from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'timer_start_ms': DateTime.now()
            .subtract(const Duration(minutes: 30))
            .millisecondsSinceEpoch,
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((_) => AppDatabase(NativeDatabase.memory())),
      ]);
      addTearDown(container.dispose);

      final state = container.read(timerNotifierProvider);
      expect(state, isA<TimerRunning>());
      final elapsed = container.read(timerNotifierProvider.notifier).elapsed;
      expect(elapsed.inMinutes, closeTo(30, 1));
    });
  });

  // Lockscreen pause flow hardening — Item 5 of the 2026-04-09 plan.
  // The native foreground service writes Dart's timer state directly to
  // SharedPreferences when the user taps Pause / Resume / Stop on the
  // notification, so cold-start reconstruction must honor those writes.
  group('TimerNotifier cold-start Paused reconciliation', () {
    test(
        'cold start with paused state (startKey=null, accKey>0) '
        'reconstructs as TimerPaused', () async {
      // Service-side pause flow: startKey removed, accKey set to the snapshot
      // at the moment the notification action fired.
      SharedPreferences.setMockInitialValues({
        'timer_paused_accumulated_secs': 150,
        'timer_profile_id': 'default',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((_) => AppDatabase(NativeDatabase.memory())),
      ]);
      addTearDown(container.dispose);

      final state = container.read(timerNotifierProvider);
      expect(state, isA<TimerPaused>(),
          reason: 'a paused snapshot in prefs must survive cold start — '
              'otherwise the user loses the state they saw on the lockscreen');
      final paused = state as TimerPaused;
      expect(paused.accumulated.inSeconds, 150);
      expect(paused.profileId, 'default');
    });

    test(
        'cold start with no state (both keys unset) reconstructs as Idle',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((_) => AppDatabase(NativeDatabase.memory())),
      ]);
      addTearDown(container.dispose);

      expect(container.read(timerNotifierProvider), isA<TimerIdle>());
    });

    test(
        'cold start with accKey=0 (never-started) reconstructs as Idle, '
        'not Paused', () async {
      // Defensive: a zero accKey should not be interpreted as a paused state.
      SharedPreferences.setMockInitialValues({
        'timer_paused_accumulated_secs': 0,
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((_) => AppDatabase(NativeDatabase.memory())),
      ]);
      addTearDown(container.dispose);

      expect(container.read(timerNotifierProvider), isA<TimerIdle>());
    });

    test(
        'cold start with both startKey set AND accKey set reconstructs '
        'as Running (startKey wins)', () async {
      // Dart's resume() writes startKey=now while keeping accKey as the
      // base. This must reconstruct as Running with accumulated from accKey.
      final thirtyMinAgo = DateTime.now()
          .subtract(const Duration(minutes: 5))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'timer_start_ms': thirtyMinAgo,
        'timer_paused_accumulated_secs': 600, // 10 min prior pause
        'timer_profile_id': 'default',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((_) => AppDatabase(NativeDatabase.memory())),
      ]);
      addTearDown(container.dispose);

      final state = container.read(timerNotifierProvider);
      expect(state, isA<TimerRunning>());
      // 5 min running + 10 min prior pause = ~15 min elapsed
      final elapsed = container.read(timerNotifierProvider.notifier).elapsed;
      expect(elapsed.inMinutes, closeTo(15, 1));
    });
  });
}
