# How to ship the PWA and the APK

Sundial targets **Android** and **the web** today (no iOS pipeline — see
[limitations.md](../limitations.md)). This covers building both.

## Android APK

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

- Core-library desugaring is enabled and the Gradle wrapper is pinned
  (`android/app/build.gradle.kts`, `android/gradle/wrapper/`), so a clean machine
  builds without extra setup beyond a JDK Flutter accepts.
- The launcher icon is generated from `assets/icon/app_icon.png` via
  `flutter_launcher_icons` (`android: true`, adaptive icon background `#F5F0E8`). If
  you change the icon, re-run `dart run flutter_launcher_icons`.
- The app declares an Android **home-screen widget** and a **timer notification**;
  both communicate with Dart over a platform channel in `main.dart`
  (`launchSource` / `timerAction`). Test them on a real device after any change to
  the timer control surfaces.

## Web PWA

```bash
flutter build web --release
# output: build/web/  (deploy this directory as static files)
```

Two things that are easy to get wrong:

1. **Drift needs its web engine shipped.** The database is configured with
   `DriftWebOptions(sqlite3Wasm: 'sqlite3.wasm', driftWorker: 'drift_worker.js')`
   (`lib/core/storage/app_database.dart`). Both files live in `web/` and must be
   served alongside the build — without them, Drift throws at startup and the app
   shows a blank screen.
2. **Persistent storage.** The web build requests persistent storage so the browser
   doesn't evict the local database under storage pressure. Keep that request in the
   web bootstrap when editing `web/index.html`.

Layout note: `main.dart` centers the app at a **760px** max width on wider viewports,
so the mobile layout reads well in a desktop browser. New screens should stay
comfortable within that width.

## Before you tag a release

```bash
flutter analyze      # zero issues
flutter test         # green (regenerate goldens only for intentional UI changes)
```

The release GitHub Actions workflow (`.github/workflows/`) runs the tests, then
builds and publishes on a `v*.*.*` tag push.
