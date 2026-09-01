# Concepts

The domain ideas behind Sundial, in prose. For the exact schema and formats see
[reference/data-model.md](reference/data-model.md); for how the layers fit,
[architecture/OVERVIEW.md](architecture/OVERVIEW.md).

## Session

A **session** is one logged stretch of outdoor time. It stores a start time, an end
time, a **duration in seconds**, a `dateDay` (a `YYYY-MM-DD` key used for grouping),
an optional profile, and an optional short note.

The duration is *stored, not derived from start/end at read time*. That is the whole
reason editing is loss-free: change the duration and it simply becomes the truth,
with no need to keep start and end consistent. When you retime a session to a
different day, its start/end move to that day and `dateDay` updates with it.

Sessions arrive three ways — the timer, manual entry ("Add Time"), and edits — and
all three write to the same `Sessions` table. Every aggregate view reads reactively
off that table, so any change updates the totals, the timeline, and the dot row
immediately.

## The timer state machine

The timer is a small sealed state machine:

- **Idle** — nothing running.
- **Running** — counting up from a start time, carrying any accumulated time from a
  prior pause, tagged with the active profile.
- **Paused** — holding accumulated time, not counting.
- **Stopped** — resolved into a saved `Session`.

It is **background-safe**: the start timestamp is persisted, so elapsed time is
correct even if the app is killed and reopened. On Android, a **home-screen widget**
and a **media-style notification** can drive the timer (pause / resume / stop) from
outside the app, over a platform channel handled in `main.dart`.

### Auto-stop

Auto-stop is a secondary, **opt-in, default-off** safeguard. It is a pure predicate —
`AutoStopService.shouldTrigger(timerStartMs, thresholdHours)` — checked when the app
resumes: if the timer has run longer than the user's threshold (2 hours by default),
the session is stopped and saved. It records nothing about *why* you were out and
never guesses from location or motion. See
[ADR-0005](adr/0005-forgiveness-over-prevention.md).

## Goals and pacing

You set an **annual goal** (default **1000 hours**) and, optionally, a **monthly**
one. Progress is shown as a fraction of the goal, and **pace** compares what you
have logged with what an even spread of the goal expects by today (goal × day of
the period ÷ days in the period, today counted). Timer, Flow and Stats say it in
words ("On pace", "12h behind pace"), and the bar's color *informs* rather than
shames:

- on pace (short by no more than one day's share) → the calm/primary color,
- slightly behind (up to a week's share) → a softer shade,
- behind → **amber**, never red.

There are no streak counters, no percentages framed as failure, and no "you're
falling behind" notifications. The number is there; the judgment is not.

## Badges

Badges are milestones on the **all-time** total. The install seeds a fixed set of
thresholds (10, 25, 50, 75, 100, then 200…1000 hours); crossing one **awards** the
badge, records an `earnedAt` timestamp, and fires a confetti animation. There is no
nag to share or to keep going — just the moment.

**Earned is earned.** A badge, once awarded, is never taken back: deleting or
shortening sessions later (correcting an honest mistake) does not un-earn it. The
invariant is *latched*: a badge is awarded the first time the all-time total reaches
its threshold, and `earnedAt` is never cleared afterwards (operator ruling; pinned by
`local_badges_repository_test.dart` and `stats_screen_test.dart`).

Badges survive a backup round-trip: only *earned* badges (id + `earnedAt`) are
written to an export, and a restore re-marks known ids, skipping any it doesn't
recognize (so old backups and newer installs interoperate).

## Profiles

A **profile** is one person in a household (a name, a color, an optional emoji).
Sessions may belong to a profile; one profile is active at a time for the timer, and
stats/history can be filtered per profile or viewed for *Everyone*. This is entirely
**local** — it is not accounts, not sync, and not a "family" feature in the cloud
sense. Viewing another profile's stats deliberately does not change the timer's
active profile.

## Focus mode vs. Full mode

The same sessions render through two surfaces, chosen by a single `AppMode`
preference:

- **Focus** (`flow`) — one screen: a **7-day dot row** (a dot filled if you logged
  any time that day — a quiet pattern, *not* a streak with a loss mechanic), the
  timer, and a single `Xh / 1000h this year` line. The only path into old data is
  tapping today's dot to fix today's total.
- **Full** (`rich`) — timer, history timeline, stats, badges, and profiles.

Switching is instant and lossless; nothing is hidden behind a mode. See
[ADR-0006](adr/0006-focus-mode-as-surface.md).

## Stats surfaces

All computed reactively off the `Sessions` table, filterable by profile:

- **Totals** — Today, This Month (vs. monthly goal), This Year (vs. annual goal),
  All-Time.
- **Cumulative chart** — running total over time.
- **Heatmap** — per-day intensity, calendar-style.
- **Monthly breakdown** — a bar per month of the current year.

## Export and import

Your data is portable. Sundial exports to **JSON** (full backup: profiles, sessions,
earned badges, annual goal), **PDF** (a clean printable summary), and **plain text**;
it imports from **JSON**. Import is robust: one malformed row is skipped, not allowed
to abort the whole import. See [reference/data-model.md § export format](reference/data-model.md#export-json-format).
