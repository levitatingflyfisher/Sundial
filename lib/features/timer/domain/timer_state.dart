// lib/features/timer/domain/timer_state.dart
import 'package:sundial/core/storage/app_database.dart';

sealed class TimerState {
  const TimerState();
}

class TimerIdle extends TimerState {
  const TimerIdle();
}

class TimerRunning extends TimerState {
  const TimerRunning({
    required this.startTime,
    required this.accumulated,
    this.profileId = 'default',
  });
  final DateTime startTime;
  final Duration accumulated;
  final String profileId;
}

class TimerPaused extends TimerState {
  const TimerPaused({required this.accumulated, this.profileId = 'default'});
  final Duration accumulated;
  final String profileId;
}

class TimerStopped extends TimerState {
  const TimerStopped({required this.session});
  final Session session;
}
