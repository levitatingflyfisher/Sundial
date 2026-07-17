import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/export/data/json_export_impl.dart';
import 'package:sundial/features/export/data/json_import_impl.dart';
import 'package:sundial/features/settings/data/local_settings_repository.dart';

/// Serializes Sundial's user data to/from a JSON [Uint8List] for encrypted
/// backup via `sanctuary_backup_ui`.
///
/// This deliberately does **not** invent a second serialization: it wraps
/// the app's existing plaintext-JSON export/import machinery
/// ([JsonExporter]/[JsonImporter], already shipped as the ".json" export
/// option) in an `{app, schemaVersion, payload}` envelope. The envelope lets
/// [restoreAll] reject a backup made for a different app, or a future schema
/// version, before the payload is ever handed to the importer — defense in
/// depth behind the AEAD context that already scopes the encrypted blob to
/// this app (SANCTUARY-BRIEF §2.3, §2.8, §4.W2).
class SundialBackupSerializer
    implements BackupSerializer, PreviewableBackupSerializer {
  final AppDatabase _db;

  const SundialBackupSerializer(this._db);

  static const String _appId = 'sundial';

  @override
  Future<Uint8List> dumpAll() async {
    final sessions = await _db.select(_db.sessions).get();
    final profiles = await _db.select(_db.profiles).get();
    final badges = await _db.select(_db.badges).get();
    final prefs = await LocalSettingsRepository(_db).getUserPrefs();

    final inner = JsonExporter().buildJson(
      sessions,
      annualGoalHours: prefs.annualGoalHours,
      profiles: profiles,
      badges: badges,
    );

    // The shared fleet envelope (BACKUP_RETENTION_SPEC §2.F). Reuses the
    // running database's own schema version rather than a second parallel
    // counter — a future migration that bumps AppDatabase.schemaVersion
    // automatically makes older-app restores fail closed on newer backups
    // (SANCTUARY-BRIEF §2.8). createdAt feeds preview/staleness copy.
    return BackupEnvelope.wrap(
      appId: _appId,
      schemaVersion: _db.schemaVersion,
      createdAt: DateTime.now(),
      payload: jsonDecode(inner) as Map<String, Object?>,
    );
  }

  /// The dry-run parse behind preview-before-restore and export
  /// verify-by-read-back: validates exactly like [restoreAll] (wrong app,
  /// future schema, malformed payload) and reports row counts — but never
  /// writes.
  @override
  Future<BackupManifest> describeBackup(Uint8List plaintext) async {
    final unwrapped = _unwrap(plaintext); // throws what restoreAll would
    _requirePayload(unwrapped.payload); // same content check as restoreAll
    return BackupEnvelope.describe(plaintext);
  }

  /// The payload-content gate [restoreAll] applies — shared so describe
  /// and restore can never drift apart again.
  static void _requirePayload(Map<String, Object?> payloadJson) {
    if (payloadJson.isEmpty || payloadJson['profiles'] is! List) {
      throw const FormatException('Missing payload in backup file');
    }
  }

  UnwrappedBackup _unwrap(Uint8List data) => BackupEnvelope.unwrap(
        data,
        expectedAppId: _appId,
        currentSchemaVersion: _db.schemaVersion,
      );

  /// Restores all user data from an OHBK envelope previously produced by
  /// [dumpAll].
  ///
  /// **Destructive:** wipes existing profiles/sessions and resets badge
  /// earned-status inside a single transaction, then re-inserts from the
  /// backup — never a partial restore (SANCTUARY-BRIEF §2.5).
  ///
  /// Throws [FormatException] for a malformed envelope, a missing/mismatched
  /// `app`, or a missing `payload`/`schemaVersion`. Throws
  /// [BackupSchemaException] when the payload's schema version is newer than
  /// this app understands.
  @override
  Future<void> restoreAll(Uint8List data) async {
    final unwrapped = _unwrap(data);
    final payloadJson = unwrapped.payload;
    _requirePayload(payloadJson);

    final payload = JsonImporter().parse(jsonEncode(payloadJson));

    await _db.transaction(() async {
      // Wipe in FK-safe order: sessions (child, references profiles.id)
      // before profiles (parent).
      await _db.delete(_db.sessions).go();
      await _db.delete(_db.profiles).go();
      // Badges are a fixed catalog (id + thresholdHours) seeded at install,
      // not per-user rows — a destructive replace resets earned status only,
      // it never drops/reinvents the catalog the way a delete-then-reinsert
      // of the whole table would.
      await _db.update(_db.badges).write(const BadgesCompanion(earnedAt: Value(null)));

      // Insert in FK order: profiles first, then sessions, then badges —
      // matching the existing JSON import's documented restore order.
      for (final p in payload.profiles) {
        await _db.into(_db.profiles).insertOnConflictUpdate(p);
      }
      for (final s in payload.sessions) {
        await _db.into(_db.sessions).insertOnConflictUpdate(s);
      }
      for (final entry in payload.earnedBadges.entries) {
        await (_db.update(_db.badges)..where((t) => t.id.equals(entry.key)))
            .write(BadgesCompanion(earnedAt: Value(entry.value)));
      }

      // F10: the annual goal is the single most important setting in a
      // yearly-goal tracker — a destructive restore must bring it back too,
      // not silently fall through to LocalSettingsRepository's 1000h
      // default. Only write it when the backup actually carries one (older
      // backups predate this field and shouldn't clobber the current goal).
      if (payload.annualGoalHours != null) {
        await LocalSettingsRepository(_db)
            .setAnnualGoalHours(payload.annualGoalHours!);
      }
    });
  }
}
