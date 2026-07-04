# ADR-0002: Drift over sqflite for local storage

- **Status:** Accepted
- **Date:** 2026-07-03 (documenting a choice load-bearing since the first commit)

## Context

Everything Sundial stores lives on-device (see
[ADR-0004](0004-local-first-ghost-tier.md)), so the local database *is* the backend.
It has to give reactive reads (stats and the history timeline update the instant a
session changes), run the same code on Android and the web, migrate cleanly as the
schema grows, and be testable without a device.

## Decision

Use **Drift** (with `drift_flutter`) as the persistence layer, over raw `sqflite`.

- Tables and the database live in `lib/core/storage/app_database.dart`; DAOs live per
  feature under `data/`.
- Reads are exposed as **streams**, so the UI recomputes reactively.
- The web build runs on `sqlite3.wasm` + `drift_worker.js` (shipped in `web/`),
  configured via `DriftWebOptions`.
- Tests use an in-memory database, so repositories are exercised for real with no
  mocking.
- Schema evolution is explicit: bump `schemaVersion` and add a step to
  `MigrationStrategy` (the schema is at v3 today — badge milestones were added in v2,
  profiles + `sessions.profileId` in v3).

## Consequences

- **Buys:** compile-time-checked, type-safe queries; reactive streams for free;
  one storage story across mobile and web; painless in-memory testing; a clear
  migration path.
- **Costs:** a code-generation step (`build_runner`) — `*.g.dart` files are generated
  and gitignored, so a fresh checkout won't compile until they're regenerated. Web
  carries the extra `sqlite3.wasm` / worker assets.
- **Forecloses:** hand-written SQL scattered across the app, and any storage engine
  that can't run in the browser.

## Alternatives considered

- **Raw `sqflite`:** no reactive streams, no compile-time query checking, and no
  web support — you'd hand-roll all three. Rejected.
- **An ORM-free key/value store (Hive, shared_preferences):** fine for the handful of
  scalar preferences (which *do* use `shared_preferences`), but wrong for relational,
  queryable, aggregatable session data. Rejected for the primary store.
