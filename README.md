# Sundial

**A local-first tracker for time spent outdoors.** Start a timer, go outside, stop
it — and log the hours against a personal yearly goal. Everything stays on your
device: no account, no tracking, no cloud required.

> **Vision in one line:** a tally of time spent outdoors, kept honest by
> *forgiveness* instead of surveillance — and kept entirely on your device. The fix
> for a forgotten timer is *editing*, not intervention. See **[VISION.md](VISION.md)**.

## What it does

- **Timer** — start / pause / stop, background-safe, with optional Android
  home-screen widget and notification controls.
- **Forgiving editing** — any session, even one just stopped, is editable with no
  lock-out. Forgot to stop? Fix the duration in two taps.
- **Manual entry** — backfill a hike you didn't track, on any past date.
- **Goals** — a yearly goal (1000 hours by default) and an optional monthly one.
  Progress *informs*, never nags: behind pace is amber, never red.
- **Stats** — Today / Month / Year / All-Time, a cumulative chart, a heatmap, and a
  per-month breakdown.
- **Badges** — milestone confetti, without any nag to share or "keep the streak."
- **Two modes** — *Focus* (one calm screen: 7-day dots, timer, yearly total) and
  *Full* (history, stats, badges, profiles). Same data, different surface.
- **Multiple profiles** — track a household locally.
- **Export / import** — JSON, PDF, and plain text out; JSON back in. Your data is
  yours.

Everything above works **fully offline, with no account**. Sync and family accounts
are designed but not yet built — see [docs/limitations.md](docs/limitations.md).

## Quickstart

Sundial's encrypted backup (.ohbk) is built on two shared packages consumed by
**sibling path dependency** (`../packages/...`, the same convention as
`eloEngine`). Clone them next to Sundial so the paths resolve:

```
packages/
  sanctuary_auth_core/     # github: levitatingflyfisher/sanctuaryAuthCore
  sanctuary_backup_ui/     # github: levitatingflyfisher/sanctuaryBackupUi
Sundial/                   # this repo
```

```bash
git clone https://github.com/levitatingflyfisher/sanctuaryAuthCore packages/sanctuary_auth_core
git clone https://github.com/levitatingflyfisher/sanctuaryBackupUi packages/sanctuary_backup_ui
git clone https://github.com/levitatingflyfisher/Sundial.git
cd Sundial
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generate Drift + Riverpod code
flutter run                                                # device, emulator, or Chrome
```

`*.g.dart` files are generated and gitignored, so the `build_runner` step is
required after a fresh checkout. See [CONTRIBUTING.md](CONTRIBUTING.md) for the full
setup, Android build notes, and PR workflow.

```bash
flutter test          # run the suite
flutter analyze       # zero issues expected
flutter build apk     # Android
flutter build web     # installable PWA
```

## Privacy

The shipped app makes **no network calls**. There is no analytics, no telemetry, and
no server — by construction, not just by promise. Fonts are bundled, so even the
first launch fetches nothing. Read exactly what does (and doesn't) leave the device,
and how to verify it yourself, in [docs/privacy-model.md](docs/privacy-model.md).

## Documentation

Full docs are organized on the [Diátaxis](https://diataxis.fr/) model — start at
**[docs/README.md](docs/README.md)**. Highlights:

- **[VISION.md](VISION.md)** — the one idea, the commitments, and an honest
  built-vs-aspirational scorecard.
- **[docs/architecture/OVERVIEW.md](docs/architecture/OVERVIEW.md)** — the layers and
  data flow, with diagrams.
- **[docs/adr/](docs/adr/)** — why each load-bearing decision was made.
- **[docs/whitepaper.md](docs/whitepaper.md)** — why this app exists and why
  local-first matters *here*.
- **[AGENTS.md](AGENTS.md)** — the guide for anyone (human or agent) changing the code.

## Tech

Flutter · Riverpod · Drift (SQLite) · go_router · Clean Architecture
(domain / data / presentation), feature-first. Runs on Android and the web (PWA).

## License

[MIT](LICENSE).
