# Contributing to Sundial

Thank you for taking the time to contribute! This document explains how to report issues, suggest features, and submit code changes.

---

## Reporting Bugs

Before opening a new issue, search existing issues to avoid duplicates.

When filing a bug report, please include:
- Flutter version (`flutter --version`)
- Device/OS and version
- Steps to reproduce
- Expected behaviour vs. actual behaviour
- Any relevant log output (`flutter logs`)

---

## Suggesting Features

Open an issue with the `enhancement` label. Describe the problem you are trying to solve rather than jumping straight to a solution — this helps discussion stay focused.

---

## Development Setup

```bash
git clone <repo-url>
cd sundial
flutter pub get
```

Sundial uses Drift ORM and Riverpod codegen. Generated `*.g.dart` files are gitignored, so you must run code generation after every fresh checkout or dependency change:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Without this step, `flutter build` will fail with "No such file or directory" errors on `*.g.dart` imports.

### Android build notes

- Java 25 is supported. Gradle wrapper is pinned in `android/gradle/wrapper/gradle-wrapper.properties`.
- Core library desugaring is enabled in `android/app/build.gradle.kts`.

---

## Code Style

All contributions must pass the following checks before review:

```bash
# Format
flutter format .

# Static analysis (must have zero issues)
flutter analyze

# Tests (must all pass)
flutter test
```

The project uses `package:flutter_lints` with standard rules — no overrides. Do not disable lint rules without a well-reasoned justification in the PR description.

---

## Testing

- Every new feature must include tests.
- Bug fixes should include a regression test where feasible.
- Tests live in `test/` and mirror the `lib/` structure:
  - `test/unit/` — domain entities, repositories, services
  - `test/widget/` — presentation layer widgets and screens
- Repository tests use an in-memory SQLite database (no mocking needed thanks to Drift's `NativeDatabase.memory()`).

---

## Pull Request Workflow

1. Fork the repository and create a feature branch from `main`:
   ```bash
   git checkout -b feat/my-feature
   ```
2. Make your changes, following the code style rules above.
3. Open a PR against the `main` branch with a clear description of what changed and why.
4. Link any related issues in the PR description (`Closes #123`).

PRs that fail `flutter analyze` or `flutter test` will not be merged.

---

## Architecture Notes

Sundial uses clean architecture with a feature-based folder layout. When adding a new feature:

1. Create a directory under `lib/features/<feature-name>/` with three sub-directories:
   - `domain/` — define entity classes and an abstract repository interface
   - `data/` — implement the repository using a Drift DAO
   - `presentation/` — screens, widgets, and Riverpod controllers/providers

2. Add database tables to `lib/services/database/tables.dart` and a new DAO under `lib/services/database/daos/`.

3. Run `dart run build_runner build --delete-conflicting-outputs` to regenerate Drift code.

4. Register the new repository provider in `lib/core/providers/repository_providers.dart`.

5. Add routes in `lib/app/router.dart`.

---

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).

Questions? Open an issue on GitHub.
