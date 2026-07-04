# ADR-0003: Riverpod for state management

- **Status:** Accepted
- **Date:** 2026-07-03 (documenting a choice load-bearing since the first commit)

## Context

The app has state that outlives any single widget (the running timer, the active
profile, user preferences, the current app mode) and derived state that must stay in
sync with the database (totals, pacing, the dot row). It needs dependency injection
that is easy to override in tests and in `main.dart`, and it needs to compose with
Drift's streams without glue.

## Decision

Use **Riverpod** (`flutter_riverpod` + `riverpod_annotation` codegen) as the single
state-management and DI mechanism.

- Repositories, DAOs, and the database are exposed as providers in
  `lib/core/providers/core_providers.dart`.
- Feature controllers are notifiers (e.g. `timer_notifier.dart`); reactive views
  watch stream-backed providers so they recompute on every data change.
- `main.dart` injects cross-cutting singletons (e.g. `SharedPreferences`) via
  `ProviderScope` overrides; tests override the same providers to inject in-memory
  fakes.

## Consequences

- **Buys:** testable, override-friendly DI with no service locator; clean
  composition with Drift streams; compile-time-safe provider wiring via codegen.
- **Costs:** the `riverpod_generator` code-gen step (shares `build_runner` with
  Drift), and a learning curve for contributors new to provider scoping.
- **Forecloses:** ad-hoc global singletons and `InheritedWidget`-by-hand plumbing.

## Alternatives considered

- **Provider / ChangeNotifier:** workable but weaker compile-time safety and clumsier
  overrides for testing. Rejected in favor of Riverpod's successor design.
- **BLoC:** more ceremony than this app's state needs; Riverpod covers the same
  ground with less boilerplate here. Rejected.
