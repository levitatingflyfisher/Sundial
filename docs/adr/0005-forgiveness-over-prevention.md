# ADR-0005: Forgiveness over prevention

- **Status:** Accepted
- **Date:** 2026-07-03 (documenting a load-bearing product principle)

## Context

The signature failure of any go-outside-and-track-it app: you start the timer, get
absorbed, and forget to stop. You return to eight hours logged for a two-hour
outing. The instinct is to *prevent* this with machinery — geofences, motion
detection, car-speed heuristics, an aggressive inactivity timeout, nagging "still
outside?" notifications. Every one of those costs battery, attention, permissions,
or trust, and each one watches the user during the exact time the app is supposed to
leave them alone.

## Decision

Solve the forgotten timer with **forgiveness, not prevention.** The primary safeguard
is that **every session is immediately and completely editable** — including one just
stopped — with **no lock-out window**. Tap it, change the duration or the date, done.

Prevention is available but demoted:

- **Auto-stop is opt-in and off by default.** When enabled, its threshold is a
  generous **2 hours** (a real hike is not an anomaly), checked by a pure predicate
  (`AutoStopService.shouldTrigger`) on app resume. Users who want it turn it on;
  users who don't never see it.
- No live GPS, no car-speed detection, no geofencing, no motion sensing.

More broadly: goals and badges **inform, never nag**. Behind pace shows amber, never
red; there are no streak counters and no "you're falling behind" notifications.

## Consequences

- **Buys:** a tool that costs the user nothing while they're outside, respects their
  attention, and needs no location or motion permissions. Correcting a mistake is
  faster than any interruption would have been.
- **Costs:** a forgotten timer *can* record a wrong duration until the user fixes it.
  We accept that, because the fix is trivial and the alternative is surveillance.
- **Forecloses:** edit lock-outs, mandatory auto-stop, and any "we know better than
  you" intervention pattern.

## Alternatives considered

- **Aggressive auto-stop / geofencing as the default fix:** intrusive, battery- and
  permission-hungry, and disrespectful of a genuine long outing. Rejected as the
  default; kept only as an explicit opt-in.
- **Short edit window ("editable for 5 minutes"):** defeats the entire point — the
  user usually notices the mistake *hours* later. Rejected outright.
