// lib/features/sessions/domain/session_invariants.dart
//
// The single source of truth for the session-duration invariant:
// 0 <= durationSecs <= 86400 (one day). Every write path — the timer stop
// paths, and the repository boundary itself — must clamp through here
// instead of re-implementing the bound inline, so the rule can never drift
// between layers. An out-of-range duration is never rejected (forgiveness
// over prevention): it is clamped, because a wildly wrong value poisons
// every SUM aggregate and auto-awards every hour-milestone badge.

/// One day — the maximum a single session may record.
const int kMaxSessionDurationSecs = 86400;

/// Clamp [durationSecs] into the valid range `[0, kMaxSessionDurationSecs]`.
int clampSessionDurationSecs(int durationSecs) =>
    durationSecs.clamp(0, kMaxSessionDurationSecs);
