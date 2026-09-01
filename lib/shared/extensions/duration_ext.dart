extension DurationExt on Duration {
  String toHhMm() {
    final h = inHours;
    final m = inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  /// The one way Sundial prints an amount of time outside: `2h 34m`, `1h`,
  /// `45m`, `45s` under a minute, `0m` for nothing. Every screen, export and
  /// the home widget use it, so one session reads the same everywhere
  /// (dmmt-01).
  String toHoursLabel() {
    final h = inHours;
    final m = inMinutes.remainder(60);
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    if (m == 0 && inSeconds > 0) return '${inSeconds}s';
    return '${m}m';
  }
}
