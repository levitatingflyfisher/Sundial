# AGENTS.md

Guidance for AI coding agents (and humans) working in this repo. This is the
top-level map; when a subdirectory grows its own `AGENTS.md`, the closest one to
the file you're editing wins.

**Read these, in order, before non-trivial work:**
1. [VISION.md](VISION.md) — what must stay true and why (the design commitments).
2. [docs/architecture/OVERVIEW.md](docs/architecture/OVERVIEW.md) — how it fits together, with diagrams.
3. [CONTRIBUTING.md](CONTRIBUTING.md) — the contributor workflow and style rules.

## Take the code as current-state, not gospel

Every line of source and every comment here was written by an AI assistant. Treat
it as **an accurate record of what currently exists, offered with gratitude and a
grain of salt** — not as a specification and not as guaranteed-correct. A comment
claiming an invariant is a *hypothesis to verify*, not a proof. If a comment and the
tests disagree, the tests win; if the tests and reality disagree, reality wins.
When you rely on a claim, confirm it (read the code, run the test) first.

## What this is

A **local-first outdoor-time tracker** (Flutter, mobile + web). Start a timer, go
outside, stop it; log time against a personal yearly goal. Everything runs on-device
via Drift/SQLite with **no account and no network calls**. Two UI surfaces (Focus
and Full) render the same data. State is Riverpod; the layout is Clean Architecture,
feature-first.

## Non-negotiables (breaking one is a regression, not a feature)

- **Local-first, no account.** Ghost mode is the whole product and must stay 100%
  functional offline. Adding a network call, an account gate, or a cloud dependency
  to the core is a regression. Any future sync is **encrypted blobs through a dumb
  relay** — never a BaaS (no Firebase/Supabase/Auth0), never plaintext.
- **No ads, no tracking, no analytics.** Do not add a telemetry, analytics, or
  crash-reporting dependency. There is deliberately no server to phone home to.
- **Forgiveness over prevention.** Never add an edit lock-out or an "only editable
  for N minutes" rule. Auto-stop stays **opt-in and off by default**.
- **Inform, never nag.** No streak-shame, no FOMO, no push nags. Behind pace is
  amber, never red.
- **TDD, always.** Reproduce → failing test → fix → `flutter test` green → commit.
  Every feature and every bugfix ships with a test. `flutter analyze` must report
  **zero issues** before you commit.
- **Atomic commits, one concern each.** The message states the *why* and the failure
  mode fixed. **No AI-assistant attribution lines** in commit messages — a deliberate
  project policy.
- **Never commit** the local agent-instruction files (e.g. `GEMINI.md`) or
  `docs/superpowers/` / `.superpowers/` — they're gitignored working artifacts (see
  `.gitignore`). This repo ships `AGENTS.md`.
- **`*.g.dart` are generated** (Drift + Riverpod, gitignored). Regenerate them with
  `build_runner`; never hand-edit.

## Where things are (progressive disclosure)

Feature-first layout: each feature owns `domain/` (entities + repository interface),
`data/` (Drift DAO + repository impl), and `presentation/` (screens/widgets +
Riverpod controllers). See [OVERVIEW.md § module map](docs/architecture/OVERVIEW.md#module-map-where-to-look).

| You're touching… | Go to |
|---|---|
| **The timer** (start/pause/stop, background, auto-stop, native controls) | `features/timer/` (`timer_notifier.dart`, `timer_state.dart`, `auto_stop_service.dart`, `timer_notification_service.dart`) + `main.dart` lifecycle/platform-channel wiring |
| **A session** (record / edit / delete / manual entry / history) | `features/sessions/` |
| **Stats, charts, goal pacing** | `features/stats/` (`stats_screen.dart`, `cumulative_chart.dart`, `heatmap_chart.dart`) |
| **Badges / milestones / confetti** | `features/badges/` |
| **Focus mode** (7-day dots, sundial face) | `features/flow_mode/` (`flow_screen.dart`, `dot_row.dart`, `sundial_face.dart`) |
| **Profiles** (multiple people, local) | `features/profiles/` |
| **Settings / preferences** | `features/settings/` (`domain/user_prefs.dart`) |
| **Export / import** | `features/export/` |
| **The database schema / tables** | `core/storage/app_database.dart` |
| **Routing / app shell / navigation** | `core/router/` |
| **Providers / dependency injection** | `core/providers/core_providers.dart` |
| **Auth tiers** (ghost today; token/named stubbed) | `core/auth/` |
| **Theme / colors / spacing / text styles** | `shared/theme/` |

Docs are organized [Diátaxis](https://diataxis.fr/)-style — see
[docs/README.md](docs/README.md) for the tutorial / how-to / reference / explanation
split.

## How to work here

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerate *.g.dart (required after checkout)
flutter test                # the suite — must be green before you commit
flutter analyze             # static analysis — must report zero issues
dart format .               # formatting
flutter build apk           # Android
flutter build web           # PWA (drift's sqlite3.wasm + drift_worker.js ship in web/)
```

- Flutter SDK `>=3.3.0`, Dart 3. Generated `*.g.dart` are gitignored, so a fresh
  checkout will not compile until you run `build_runner`.
- **Adding a feature?** Create `lib/features/<name>/{domain,data,presentation}/`,
  add its table(s) to `core/storage/app_database.dart` (bump `schemaVersion` and add
  a migration step), regenerate with `build_runner`, register the repository
  provider in `core/providers/core_providers.dart`, and add a route in
  `core/router/`.
- **Web is centered at 760px** (`main.dart`) so the mobile layout reads well on a
  desktop browser; keep new screens comfortable inside that width.
- **Android native controls**: the home-screen widget (`home_widget`) and the
  media-style timer notification talk to Dart over a platform channel handled in
  `main.dart` (`launchSource` / `timerAction`). Touch both sides when you change
  timer control surfaces.
- The default branch is `master`.

## When you're unsure

Prefer the offline/on-device path to anything networked. Prefer forgiveness (let the
user fix it) to prevention (stop the user). Prefer matching the surrounding
feature-folder structure to inventing a new pattern. When in doubt about *why* a
decision was made, grep [docs/adr/](docs/adr/) before reopening it — you may be
re-litigating a settled trade-off. And keep Ghost mode whole: if a change would make
the core need a network or an account, it's the wrong change.
