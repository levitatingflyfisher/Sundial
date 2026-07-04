# How to build and run Sundial

Task-oriented. Assumes a working Flutter toolchain (`flutter doctor` is happy).

## 1. Get the code and its generated sources

```bash
git clone https://github.com/levitatingflyfisher/Sundial.git
cd Sundial
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

The `build_runner` step is **required**, not optional: Drift tables and Riverpod
providers generate `*.g.dart` files that are gitignored, so a fresh checkout will not
compile until you run it. If you later change a table or an annotated provider, run it
again (or `dart run build_runner watch` while developing).

## 2. Run it

```bash
flutter run              # pick a connected device / emulator
flutter run -d chrome    # run as a web app
```

## 3. Test and analyze

```bash
flutter test             # full suite: unit, widget, golden/visual
flutter analyze          # must report zero issues
dart format .            # formatting
```

Notes on the test suite:

- **Repository tests** use an in-memory database (`NativeDatabase.memory()` via
  Drift), so they exercise real query logic with no mocking.
- **Golden / visual tests** live under `test/visual/` and `test/features/**/goldens/`.
  If an *intentional* UI change makes them fail, regenerate the baselines:
  ```bash
  flutter test --update-goldens
  ```
  Review the image diffs before committing updated goldens.
- An end-to-end timer flow lives in `integration_test/`.

## 4. Common snags

- **`No such file or directory` on a `*.g.dart` import** → you skipped step 1's
  `build_runner`. Run it.
- **Android build** → Java 25 is supported; core-library desugaring is enabled in
  `android/app/build.gradle.kts`; the Gradle wrapper version is pinned. See
  [CONTRIBUTING.md](../../CONTRIBUTING.md) for details.
- **Web shows a blank screen** → confirm `web/sqlite3.wasm` and `web/drift_worker.js`
  are present; Drift needs them (see [ship-pwa-and-apk.md](ship-pwa-and-apk.md)).
