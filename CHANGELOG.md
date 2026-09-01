# Changelog

All notable changes to Sundial will be documented in this file.

## [Unreleased]

### Changed
- Adopted the shared `openhearth_design` package (path dep): the text
  theme comes from `OhTypography.materialTextTheme` and the
  canonical-valued palette entries (sage500/onPace, linen50, linen900,
  warmDark) alias `OhColors` tokens. Since 0.7.0 the ladder is the fleet's
  new one (body text 14 → 16); the design-sync test pins its values.
- Lora and Nunito now come from `openhearth_design` (0.7.2+) as package
  fonts instead of Sundial's own copy: one source of truth for type,
  ~340 KB less shipped in this app. `assets/fonts/` and its `fonts:`
  pubspec block are gone; `test/shared/theme/offline_fonts_test.dart`
  now asserts the package fonts resolve instead of pinning a local copy.
- Pace is computed: Stats, Timer and Flow compare the year (and month)
  with what the goal expects by today and say so in words; the bar is
  amber only when genuinely behind, never red.
- One formatter for time outside: Flow, the all-time chart, the PDF and
  the home widget no longer print a 30-minute session as 0h or 1h.
- Theme: light, dark or follow the phone (default), one control in the
  app bar; a stored dark stays dark, a stored light follows the phone.
- Badges are never revoked once earned.
- Swipe-delete asks first and names the session; removing a person acts
  at once with an Undo that does not expire; Edit Session's back keeps
  typed work; failures show a plain sentence, never the raw exception.
- Each screen caps its content at 640dp and centres it on wide screens
  (was a 760px box around the whole app, bars included).
- Backup & Restore names its areas and never shows a heading over
  nothing; a dismissible "finish setup" line sits atop Settings while
  backup setup is unfinished; recovery words are kept per app on web.

### Added
- `DateTimeExt.dateOnly`, `DateTimeExt.startOfWeek` and the DST-safe
  `daysBetweenDates` helper, kept byte-aligned with the fleet's shared
  extension file.
- Snapshot vault ("Previous backups" on the Backup & Restore screen):
  every encrypted export and every restore leaves a stamped on-device
  snapshot (keep-10, pinnable) you can restore, pin or delete.
- Mandatory pre-restore snapshot: a restore refuses to run unless the
  current data was snapshotted (and the snapshot verified) first —
  restoring is now reversible.
- Preview before restore: the confirm dialog shows the backup's age and
  per-table row counts next to what's on the device now.
- Encrypted exports verify themselves by read-back before reporting
  success, and the `.ohbk` envelope now carries a `createdAt` stamp
  (older backups still restore; older app versions still read new
  backups).
- Silent freshness snapshot when the newest one is older than 7 days.
- Fleet conformance suite (`oh_fleet_conformance` dev dep +
  `test/fleet_conformance_test.dart`): canonical design package, backup
  retention, size-budget ratchet (`budgets.json`), the exact Android
  permission surface and the harness canon are now tests that can fail.
- Push-triggered CI (`ci.yml`: analyze + full test suite on every
  push/PR, fleet Flutter pin 3.38.7); the release workflow now clones
  every sibling path dep (ohStyle + ohFleetConformance included).

### Fixed
- `DateTimeExt.startOfWeek` is now DST-safe: calendar arithmetic
  (`DateTime(y, m, d - n)`) instead of Duration subtraction, so a
  daylight-saving transition inside the week can no longer shift the
  computed Monday to 23:00/01:00 beside midnight (pinned by a
  TZ=America/Santiago child-process test).
- Goldens now render lucide icons for real: `flutter_test_config.dart`
  synced to the fleet's FontManifest-aware canon, which loads every
  bundled font (the old local variant skipped lucide_flutter's icon
  font, so goldens showed placeholder boxes where icons belong).
