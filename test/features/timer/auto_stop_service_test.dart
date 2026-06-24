import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/timer/data/auto_stop_service.dart';

void main() {
  group('AutoStopService', () {
    test('shouldTrigger returns false when timer not running', () {
      expect(
        AutoStopService.shouldTrigger(
          timerStartMs: null,
          thresholdHours: 2,
        ),
        isFalse,
      );
    });

    test('shouldTrigger returns false when within threshold', () {
      final startMs = DateTime.now()
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch;
      expect(
        AutoStopService.shouldTrigger(
          timerStartMs: startMs,
          thresholdHours: 2,
        ),
        isFalse,
      );
    });

    test('shouldTrigger returns true when past threshold', () {
      final startMs = DateTime.now()
          .subtract(const Duration(hours: 3))
          .millisecondsSinceEpoch;
      expect(
        AutoStopService.shouldTrigger(
          timerStartMs: startMs,
          thresholdHours: 2,
        ),
        isTrue,
      );
    });
  });
}
