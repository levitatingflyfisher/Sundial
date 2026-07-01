# Limitations

Read this before adopting Sundial or building on it. It is the honest list of what
the app does *not* do today. For the framing behind these lines, see the
[VISION scorecard](../VISION.md#honest-scorecard--built-vs-aspirational); for
per-feature status, [reference/feature-status.md](reference/feature-status.md).

## No sync, no accounts (yet)

Sundial is **Ghost tier only**: everything is on one device, in one local database.

- There is **no cross-device sync**. Your phone and your partner's phone do not share
  data.
- There are **no accounts**. The Token (anonymous sync) and Named (family accounts)
  tiers are *designed but not built* — `upgradeToToken()` and `upgradeToNamed()`
  throw `UnimplementedError`. There is no relay, no encryption code, and no shared
  family view. See [ADR-0004](adr/0004-local-first-ghost-tier.md).

**Consequence:** back up regularly. The only copy of your data is on the device; if
you lose or wipe it without a JSON/PDF export, the data is gone.

## No enrichment features

The following are described in product notes but **not implemented**:

- **Photos per session.**
- **Adventure map** (manual pins; never live GPS).
- **Achievements beyond the fixed badge milestones.**
- **Light social sharing** ("share my year" cards).

The database reserves nullable `locationLabel` / `lat` / `lng` columns for the map,
but nothing reads or writes them yet.

## Platform gaps

- **iOS is not a target today.** The launcher-icon config and the release pipeline
  build for **Android and web** only. The Flutter code is not iOS-hostile, but there
  is no iOS build, signing, or release story.
- **Web** runs Drift on `sqlite3.wasm` + a worker and centers the layout at 760px;
  it's a genuine PWA, but it is the mobile layout adapted, not a bespoke desktop UI.

## Behavior caveats

- **Badges can be revoked.** If your all-time total drops back below a milestone
  (after deleting or shortening sessions), that badge is un-earned. If you expected
  milestones to be permanent, they currently are not — see
  [concepts.md § badges](concepts.md#badges).
- **No CSV export.** Export is JSON, PDF, and plain text; import is JSON only.
- **Auto-stop is coarse.** It fires on the *first app resume* after the threshold is
  exceeded, not on a wall-clock timer, and only if you enabled it. A session left
  running while the app is never reopened won't auto-stop until you next open the app.
- **No reminders or notifications to go outside.** By design — this is a tool, not a
  nag. If you want prompting, Sundial won't provide it.

## What this is *not*

Not a fitness tracker, not a GPS route recorder, not a social network, not a
screen-time blocker. It counts hours you tell it about (via the timer or manual
entry) and helps you see the pattern. That's the whole job.
