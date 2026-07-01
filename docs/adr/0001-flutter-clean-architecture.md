# ADR-0001: Flutter + Clean Architecture, feature-first

- **Status:** Accepted
- **Date:** 2026-07-03 (documenting a choice load-bearing since the first commit)

## Context

Sundial needs to run on phones and the web from one codebase, stay testable enough
to trust with a household's data, and be legible to future contributors (human and
agent) who arrive with no context. Two shapes were on the table: a quick,
pragmatic "screens call the database" layout, or a layered one that costs a little
ceremony up front and pays it back in isolation.

## Decision

Build on **Flutter**, structured as **Clean Architecture, feature-first**. Each
feature (`lib/features/<name>/`) is a vertical slice with three layers:

- `domain/` — plain-Dart entities and an **abstract repository interface**. No
  Flutter, no Drift, no I/O.
- `data/` — a Drift DAO plus the repository *implementation* of the domain interface.
- `presentation/` — screens, widgets, and Riverpod controllers.

Dependencies point inward: presentation → domain ← data. The presentation layer
talks only to repository *interfaces*; it never imports a DAO or a Drift row type
directly.

## Consequences

- **Buys:** the repository interface is a clean seam — tests run the real logic
  against an in-memory database, and a future sync implementation can slot in behind
  the same interface without the UI changing. One codebase ships to Android and web.
- **Costs:** more files and more boilerplate per feature than a flat layout. A new
  feature means creating three directories and wiring a provider before any pixels
  move.
- **Forecloses:** letting a screen reach straight into Drift for a "quick" query.
  That shortcut is the thing this structure exists to prevent.

## Alternatives considered

- **Flat / pragmatic (widgets query the DB):** faster to start, but the data access
  spreads into the UI and the app becomes hard to test and impossible to re-target
  (e.g. add sync) without a rewrite. Rejected.
- **A different cross-platform toolkit (React Native, native ×2):** Flutter's single
  codebase to mobile *and* web, plus first-class Drift/Riverpod support, made it the
  clear fit for the OpenHearth stack.
