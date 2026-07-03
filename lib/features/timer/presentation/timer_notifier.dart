// lib/features/timer/presentation/timer_notifier.dart
import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/timer/data/timer_notification_service.dart';
import 'package:sundial/features/timer/domain/timer_state.dart';

part 'timer_notifier.g.dart';

@riverpod
class TimerNotifier extends _$TimerNotifier {
  Timer? _ticker;
  int _tickCount = 0;
  static const _startKey = 'timer_start_ms';
  static const _accKey = 'timer_paused_accumulated_secs';
  static const _profileKey = 'timer_profile_id';
  static final _dayFmt = DateFormat('yyyy-MM-dd');

  int get _durationMs {
    final prefs = ref.read(userPrefsProvider).valueOrNull;
    return (prefs?.autoStopThresholdHours ?? 2) * 3600 * 1000;
  }

  @override
  TimerState build() {
    ref.onDispose(() => _ticker?.cancel());
    return _reconstructFromPrefs();
  }

  TimerState _reconstructFromPrefs() {
    final prefs = ref.read(sharedPreferencesProvider);
    final startMs = prefs.getInt(_startKey);
    final accSecs = prefs.getInt(_accKey) ?? 0;
    final profileId = prefs.getString(_profileKey) ?? 'default';

    // Idle: neither a running start time nor a paused snapshot.
    if (startMs == null && accSecs <= 0) return const TimerIdle();

    // Paused: no running start, but a positive accumulated snapshot. This
    // path handles service-side pause (lockscreen) when Dart was dead — the
    // foreground service writes the correct accKey to SharedPreferences so
    // the user doesn't lose the moment they tapped Pause.
    if (startMs == null) {
      final pausedState = TimerPaused(
        accumulated: Duration(seconds: accSecs),
        profileId: profileId,
      );
      // Start the ticker so the UI stays alive. Notification actions are
      // delivered via MethodChannel push (primary) or SharedPrefs flag
      // polling (fallback when engine was dead at tap time).
      _startTicker();
      unawaited(showTimerPaused(profileId, Duration(seconds: accSecs),
          durationMs: _durationMs));
      return pausedState;
    }

    // Running: start time present; accumulated may carry over from a prior
    // pause-resume cycle.
    final reconstructed = TimerRunning(
      startTime: DateTime.fromMillisecondsSinceEpoch(startMs),
      accumulated: Duration(seconds: accSecs),
      profileId: profileId,
    );
    _startTicker();

    final stopKey = _notifStopKey(profileId);
    if (prefs.getBool(stopKey) == true) {
      Future.microtask(() async {
        await prefs.remove(stopKey);
        await stopAndSave();
      });
    } else {
      unawaited(showTimerRunning(
        profileId: profileId,
        startTime: DateTime.fromMillisecondsSinceEpoch(startMs),
        accumulated: Duration(seconds: accSecs),
        durationMs: _durationMs,
      ));
    }
    return reconstructed;
  }

  void _startTicker() {
    _ticker?.cancel();
    _tickCount = 0;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.reload();

      final profileId = switch (state) {
        TimerRunning(:final profileId) => profileId,
        TimerPaused(:final profileId) => profileId,
        _ => 'default',
      };

      if (prefs.getBool(_notifStopKey(profileId)) == true) {
        await prefs.remove(_notifStopKey(profileId));
        await stopAndSave();
        return;
      }
      if (prefs.getBool(_notifPauseKey(profileId)) == true) {
        await prefs.remove(_notifPauseKey(profileId));
        await pause();
        return;
      }
      if (prefs.getBool(_notifResumeKey(profileId)) == true) {
        await prefs.remove(_notifResumeKey(profileId));
        await resume();
        return;
      }

      // Re-emit state so Riverpod triggers UI rebuilds with fresh elapsed time.
      if (state is TimerRunning) {
        final r = state as TimerRunning;
        state = TimerRunning(
          startTime: r.startTime,
          accumulated: r.accumulated,
          profileId: r.profileId,
        );
      }

      // Refresh home widget every 60s while the timer runs.
      _tickCount++;
      if (_tickCount % 60 == 0 && state is TimerRunning) {
        _updateHomeWidget(_dayFmt.format(DateTime.now()));
      }
    });
  }

  Future<void> start() async {
    if (state is! TimerIdle) return;
    final profileId = ref.read(activeProfileIdProvider);
    final now = DateTime.now();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_startKey, now.millisecondsSinceEpoch);
    await prefs.setString(_profileKey, profileId);
    await prefs.remove(_accKey);
    state = TimerRunning(
      startTime: now,
      accumulated: Duration.zero,
      profileId: profileId,
    );
    _startTicker();
    unawaited(showTimerRunning(
      profileId: profileId,
      startTime: now,
      durationMs: _durationMs,
    ));
    _updateHomeWidget(_dayFmt.format(now));
  }

  Future<void> pause({bool fromNative = false}) async {
    final current = state;
    if (current is! TimerRunning) return;
    final elapsed = _computeElapsed(current);
    final prefs = ref.read(sharedPreferencesProvider);
    if (fromNative) {
      // Native already wrote SharedPrefs via writeDartPausedState.
      // Clear the pending flag so the ticker doesn't double-fire.
      await prefs.remove(_notifPauseKey(current.profileId));
    } else {
      await prefs.remove(_startKey);
      await prefs.setInt(_accKey, elapsed.inSeconds);
    }
    state = TimerPaused(accumulated: elapsed, profileId: current.profileId);
    if (!fromNative) {
      unawaited(showTimerPaused(current.profileId, elapsed,
          durationMs: _durationMs));
    }
  }

  Future<void> resume({bool fromNative = false}) async {
    final current = state;
    if (current is! TimerPaused) return;
    final now = DateTime.now();
    final prefs = ref.read(sharedPreferencesProvider);
    if (fromNative) {
      await prefs.remove(_notifResumeKey(current.profileId));
    } else {
      await prefs.setInt(_startKey, now.millisecondsSinceEpoch);
      await prefs.setString(_profileKey, current.profileId);
      await prefs.setInt(_accKey, current.accumulated.inSeconds);
    }
    state = TimerRunning(
      startTime: now,
      accumulated: current.accumulated,
      profileId: current.profileId,
    );
    _startTicker();
    if (!fromNative) {
      unawaited(showTimerRunning(
        profileId: current.profileId,
        startTime: now,
        accumulated: current.accumulated,
        durationMs: _durationMs,
      ));
    }
  }

  Future<Session> buildDraftSession() async {
    final current = state;
    if (current is! TimerRunning && current is! TimerPaused) {
      throw StateError('Cannot build draft session in state: $current');
    }

    _ticker?.cancel();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_startKey);
    await prefs.remove(_accKey);
    await prefs.remove(_profileKey);

    final now = DateTime.now();
    final Duration elapsed;
    final DateTime startTime;
    final String profileId;

    if (current is TimerRunning) {
      elapsed = _computeElapsed(current);
      startTime = current.startTime;
      profileId = current.profileId;
    } else {
      final paused = current as TimerPaused;
      elapsed = paused.accumulated;
      startTime = now.subtract(elapsed);
      profileId = paused.profileId;
    }

    final session = Session(
      id: const Uuid().v4(),
      startTime: startTime.millisecondsSinceEpoch,
      endTime: now.millisecondsSinceEpoch,
      durationSecs: elapsed.inSeconds.clamp(0, 86400),
      notes: null,
      dateDay: _dayFmt.format(startTime),
      profileId: profileId,
      locationLabel: null,
      lat: null,
      lng: null,
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );

    state = TimerStopped(session: session);
    return session;
  }

  Future<void> confirmSession(Session session) async {
    final repo = ref.read(sessionsRepositoryProvider);
    // 'everyone' sessions store profileId=null — counts once in stats, appears
    // in every profile's filtered view via the IS NULL clause in watchAllFiltered.
    if (session.profileId == kEveryoneProfileId) {
      final nullSession = session.copyWith(profileId: const Value(null));
      await repo.saveSession(nullSession);
    } else {
      await repo.saveSession(session);
    }
    final newBadges =
        await ref.read(badgesRepositoryProvider).checkAndAwardMilestones();
    if (newBadges.isNotEmpty) {
      ref.read(newlyEarnedBadgesProvider.notifier).state = newBadges;
    }
    final profileId = session.profileId ?? 'default';
    state = const TimerIdle();
    _updateHomeWidget(session.dateDay);
    unawaited(dismissTimerNotification(profileId));
  }

  /// Auto-stop path: build the elapsed session AND persist it immediately.
  /// buildDraftSession() clears the durable timer keys, so the draft would
  /// otherwise live only in memory — a forgotten multi-hour timer would be lost
  /// if the app were killed before the user got to Review & Save. Auto-stop
  /// means the user isn't there to review, so we save it (they can still edit or
  /// delete it from history).
  Future<void> autoStopAndSave() async {
    final current = state;
    if (current is! TimerRunning && current is! TimerPaused) return;
    final draft = await buildDraftSession();
    await confirmSession(draft);
  }

  Future<Session> stopAndSave({bool fromNative = false}) async {
    final current = state;
    if (current is! TimerRunning && current is! TimerPaused) {
      throw StateError('Cannot stop in state: $current');
    }

    _ticker?.cancel();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_startKey);
    await prefs.remove(_accKey);
    await prefs.remove(_profileKey);

    final now = DateTime.now();
    final Duration elapsed;
    final DateTime startTime;
    final String profileId;

    if (current is TimerRunning) {
      elapsed = _computeElapsed(current);
      startTime = current.startTime;
      profileId = current.profileId;
    } else {
      final paused = current as TimerPaused;
      elapsed = paused.accumulated;
      startTime = now.subtract(elapsed);
      profileId = paused.profileId;
    }

    if (fromNative) {
      await prefs.remove(_notifStopKey(profileId));
    }

    final baseId = const Uuid().v4();
    final repo = ref.read(sessionsRepositoryProvider);

    final effectiveProfileId =
        profileId == kEveryoneProfileId ? null : profileId;

    final firstSession = Session(
      id: baseId,
      startTime: startTime.millisecondsSinceEpoch,
      endTime: now.millisecondsSinceEpoch,
      durationSecs: elapsed.inSeconds.clamp(0, 86400),
      notes: null,
      dateDay: _dayFmt.format(startTime),
      profileId: effectiveProfileId,
      locationLabel: null, lat: null, lng: null,
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );
    await repo.saveSession(firstSession);

    final newBadges =
        await ref.read(badgesRepositoryProvider).checkAndAwardMilestones();
    if (newBadges.isNotEmpty) {
      ref.read(newlyEarnedBadgesProvider.notifier).state = newBadges;
    }
    state = const TimerIdle();
    _updateHomeWidget(firstSession.dateDay);
    if (!fromNative) {
      unawaited(dismissTimerNotification(profileId));
    }
    return firstSession;
  }

  Future<void> refreshWidget(String dateDay) => _updateHomeWidget(dateDay);

  Future<void> _updateHomeWidget(String dateDay) async {
    try {
      var secs = await ref
          .read(sessionsRepositoryProvider)
          .watchSecondsForDay(dateDay)
          .first;
      // Include active timer elapsed if the timer is running or paused today.
      if (state is TimerRunning) {
        secs += elapsed.inSeconds;
      } else if (state case TimerPaused(:final accumulated)) {
        secs += accumulated.inSeconds;
      }
      final h = secs ~/ 3600;
      final m = (secs % 3600) ~/ 60;
      final label = h > 0 ? (m > 0 ? '${h}h ${m}m' : '${h}h') : '${m}m';
      await HomeWidget.saveWidgetData<String>('today_hours', label);
      await HomeWidget.updateWidget(
        androidName: 'SundialWidgetProvider',
        qualifiedAndroidName:
            'com.openhearth.sundial.SundialWidgetProvider',
      );
    } catch (e) {
      debugPrint('[Widget] update failed: $e');
    }
  }

  void discard() {
    final profileId = switch (state) {
      TimerRunning(:final profileId) => profileId,
      TimerPaused(:final profileId) => profileId,
      TimerStopped(:final session) => session.profileId ?? 'default',
      _ => 'default',
    };
    state = const TimerIdle();
    unawaited(dismissTimerNotification(profileId));
  }

  Duration get elapsed => switch (state) {
    TimerRunning(:final startTime, :final accumulated, profileId: _) =>
      _computeElapsed(TimerRunning(
        startTime: startTime,
        accumulated: accumulated,
      )),
    TimerPaused(:final accumulated, profileId: _) => accumulated,
    _ => Duration.zero,
  };

  Duration _computeElapsed(TimerRunning r) => Duration(
    seconds: DateTime.now().difference(r.startTime).inSeconds +
        r.accumulated.inSeconds,
  );

  // Notification flag key helpers — default profile uses legacy bare keys
  // so existing installs aren't affected on upgrade.
  static String _notifStopKey(String profileId) =>
      profileId == 'default' ? notifPendingStop : '${notifPendingStop}_$profileId';
  static String _notifPauseKey(String profileId) =>
      profileId == 'default' ? notifPendingPause : '${notifPendingPause}_$profileId';
  static String _notifResumeKey(String profileId) =>
      profileId == 'default' ? notifPendingResume : '${notifPendingResume}_$profileId';
}
