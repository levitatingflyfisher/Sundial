# Reference: feature status

What's shipped, partial, or planned — grounded in the code as of `0.1.0`. Legend:
**Shipped** = built and tested · **Partial** = present but incomplete/stubbed ·
**Planned** = designed, not built.

## Core (Ghost tier — local, offline)

| Feature | Status | Notes |
|---|---|---|
| Timer (start / pause / stop) | Shipped | Sealed state machine; background-safe |
| Auto-stop | Shipped | **Opt-in, off by default**, 2h threshold, checked on resume |
| Android widget + timer notification | Shipped | Platform channel in `main.dart` |
| Manual entry ("Add Time") | Shipped | Any past date |
| Session editing (duration / date / notes) | Shipped | No lock-out; retiming moves start/end/`dateDay` |
| Delete session | Shipped | With confirm |
| History timeline | Shipped | Reverse chronological, profile-filterable |
| Session notes | Shipped | Short label, optional |
| Goals (annual + optional monthly) | Shipped | Default 1000h/yr; amber-when-behind |
| Stats (today / month / year / all-time) | Shipped | Reactive off `Sessions` |
| Cumulative chart | Shipped | |
| Heatmap | Shipped | |
| Monthly breakdown | Shipped | Bar per month of the current year |
| Badges + confetti | Shipped | Fixed milestone set; **revocable** (see caveat) |
| Focus / Full modes | Shipped | Single `AppMode` preference |
| Focus 7-day dot row | Shipped | Tap today's dot to edit today's total |
| Multiple profiles | Shipped | **Local** only — not accounts/sync |
| Export: JSON / PDF / plain text | Shipped | |
| Import: JSON | Shipped | Row-tolerant |
| Preferences: dark mode, 12/24h, week start, timer style | Shipped | See [data-model.md](data-model.md) |
| Onboarding (mode choice) | Shipped | |

## Sync & accounts

| Feature | Status | Notes |
|---|---|---|
| Ghost tier (local, no account) | Shipped | The only live tier |
| Token tier (anonymous multi-device sync) | Planned | `upgradeToToken()` throws `UnimplementedError` |
| Named tier (family accounts) | Planned | `upgradeToNamed()` throws `UnimplementedError` |
| Shared family view / calendar | Planned | Depends on sync |
| Encrypted-blob relay | Planned | Design in [ADR-0004](../adr/0004-local-first-ghost-tier.md) |

## Enrichment

| Feature | Status | Notes |
|---|---|---|
| Location columns on sessions | Partial | Nullable `locationLabel`/`lat`/`lng` exist; unused |
| Adventure map (manual pins) | Planned | No live GPS, ever |
| Photos per session | Planned | |
| Achievements beyond badges | Planned | |
| Light social sharing ("share my year") | Planned | Opt-in only if built |

## Platforms

| Target | Status | Notes |
|---|---|---|
| Android | Shipped | APK build + release workflow |
| Web (PWA) | Shipped | Drift on `sqlite3.wasm`; 760px-centered layout |
| iOS | Planned | No build/signing/release pipeline today |
| Desktop | Planned | Stretch |

## Caveats

- **Badge revocation:** a badge un-earns if the all-time total drops below its
  threshold. See [concepts.md § badges](../concepts.md#badges).
- **No CSV export.** JSON / PDF / text only.

For the reasoning behind the local-first, no-account posture and the other
load-bearing choices, see the [ADRs](../adr/).
