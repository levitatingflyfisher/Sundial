/// Pure utility — no Flutter dependencies, fully unit-testable.
class AutoStopService {
  AutoStopService._();

  /// Returns true if the timer has been running longer than [thresholdHours].
  static bool shouldTrigger({
    required int? timerStartMs,
    required int thresholdHours,
  }) {
    if (timerStartMs == null) return false;
    final start = DateTime.fromMillisecondsSinceEpoch(timerStartMs);
    final elapsed = DateTime.now().difference(start);
    return elapsed.inHours >= thresholdHours;
  }
}
