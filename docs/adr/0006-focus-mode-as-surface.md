# ADR-0006: Flow mode is a UI surface over shared data

- **Status:** Accepted
- **Date:** 2026-07-03 (documenting a load-bearing product/design choice)

## Context

Two kinds of user want two different things from the same app. One wants a
dashboard — history, charts, badges, per-person breakdowns. The other wants a
*habit*: one button, one number, a quiet sense of whether they're keeping up, and
nothing else competing for attention. Serving both could mean two apps, a stripped
"lite" build, or a paywalled tier. All three fragment the product and the data.

## Decision

Ship **one app with two rendering surfaces over identical data:**

- **Flow mode** (`AppMode.flow`) — a single screen: a 7-day dot row, the timer, and
  a bare `247h / 1000h this year`. No tabs, no cards, no badges surfaced.
- **Rich mode** (`AppMode.rich`) — the timer plus history, stats, badges, and
  profiles.

The choice is a **single `AppMode` preference**, toggled anytime with the mode pill.
*(2026-10: onboarding no longer asks. Flow is the default, and Flow offers Rich once,
after the first saved session; batch 1b, ruling Q-D1.)* It requires **zero schema changes**: the dot row is just a
different query over the same `Sessions` table the history view reads. Switching is
instant and lossless — badges still accrue silently in Flow mode; all history is
right there when you switch to Full.

## Consequences

- **Buys:** one codebase, one data model, and a genuine calm mode for people who want
  it — with a lossless escape hatch (switch to Full to fix an old session, switch
  back). Neither mode is a lesser tier; both are free, forever.
- **Costs:** presentation code must handle both surfaces, and any new data feature
  should consider how (or whether) it appears in Flow mode. Flow mode deliberately
  offers only one path into old data (tap today's dot to edit today's total).
- **Forecloses:** implementing Flow mode as a separate build, a feature gate, or a
  paid tier. It is a lens, never a limitation.

## Alternatives considered

- **A separate "lite" app:** duplicate code, split data, no lossless switch.
  Rejected.
- **A paywalled "pro" tier for Rich mode:** turns a focus preference into a revenue
  gate and contradicts the no-paywall ethos. Rejected.
