// lib/features/timer/data/timer_notification_service.dart
import 'package:flutter/services.dart';

// SharedPreferences keys — read by TimerNotifier ticker every second.
// For the default profile, these are the bare keys (backward-compatible).
// For other profiles, the notifier appends '_$profileId'.
const notifPendingStop = 'notif_pending_stop';
const notifPendingPause = 'notif_pending_pause';
const notifPendingResume = 'notif_pending_resume';

const _channel = MethodChannel('com.openhearth.sundial/media_session');

/// Exposed so main.dart can install a `setMethodCallHandler` for host→Dart
/// calls (e.g. the widget-tap `launchSource` signal). Stays on the same
/// channel the native side already listens to.
MethodChannel get mediaSessionChannel => _channel;

/// Call once from main() before runApp.
Future<void> initTimerNotifications() async {
  try {
    await _channel.invokeMethod<void>('requestPermission');
  } catch (_) {}
}

Future<void> showTimerRunning({
  required String profileId,
  required DateTime startTime,
  Duration accumulated = Duration.zero,
  int durationMs = 7200000,
}) async {
  try {
    await _channel.invokeMethod<void>('showRunning', {
      'profileId': profileId,
      'startTimeMs': startTime.millisecondsSinceEpoch,
      'accumulatedMs': accumulated.inMilliseconds,
      'durationMs': durationMs,
    });
  } catch (_) {}
}

Future<void> showTimerPaused(String profileId, Duration accumulated,
    {int durationMs = 7200000}) async {
  try {
    await _channel.invokeMethod<void>('showPaused', {
      'profileId': profileId,
      'accumulatedSecs': accumulated.inSeconds,
      'durationMs': durationMs,
    });
  } catch (_) {}
}

Future<void> dismissTimerNotification(String profileId) async {
  try {
    await _channel.invokeMethod<void>('dismiss', {
      'profileId': profileId,
    });
  } catch (_) {}
}
