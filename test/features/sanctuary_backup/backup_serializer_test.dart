// Round-trip + envelope tests for the encrypted-backup (.ohbk) serializer.
//
// SundialBackupSerializer wraps the app's EXISTING JsonExporter/JsonImporter
// machinery in an `{app, schemaVersion, payload}` envelope
// (SANCTUARY-BRIEF §2.8, §4.W2) rather than inventing a second
// serialization. These tests pin:
//
//   1. dumpAll produces a valid envelope carrying the app id + schema version.
//   2. restoreAll round-trips sessions/profiles/badges through the same DB.
//   3. restoreAll is destructive: pre-existing rows not in the backup are gone.
//   4. restoreAll rejects a wrong app id and a future schema version.
//   5. Badge catalog rows (id/thresholdHours) always survive a restore even
//      when a locally-earned badge is absent from the backup — only earned
//      status is destructively replaced, never the catalog itself.

import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/badges/data/badges_dao.dart';
import 'package:sundial/features/badges/data/local_badges_repository.dart';
import 'package:sundial/features/sanctuary_backup/data/backup_serializer.dart';
import 'package:sundial/features/sessions/data/sessions_dao.dart';
import 'package:sundial/features/settings/data/local_settings_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late SundialBackupSerializer serializer;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    serializer = SundialBackupSerializer(db);
  });

  tearDown(() => db.close());

  Future<void> seedProfile(String id, String name) => db.into(db.profiles).insert(
        ProfilesCompanion.insert(
          id: id,
          name: name,
          colorValue: 0xFF5E9478,
          createdAt: 1700000000000,
        ),
      );

  Future<void> seedSession(String id,
          {String? profileId, int durationSecs = 3600}) =>
      db.into(db.sessions).insert(
            SessionsCompanion.insert(
              id: id,
              startTime: 0,
              endTime: durationSecs * 1000,
              durationSecs: durationSecs,
              dateDay: '2026-04-01',
              profileId: Value(profileId),
              createdAt: 0,
              updatedAt: 0,
            ),
          );

  group('dumpAll', () {
    test('envelope carries a UTC createdAt stamp (v2 retention spec)',
        () async {
      final bytes = await serializer.dumpAll();
      final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final createdAt = DateTime.parse(envelope['createdAt'] as String);
      expect(createdAt.isUtc, isTrue);
      expect(DateTime.now().toUtc().difference(createdAt).inMinutes,
          lessThan(5));
    });

    test(
        'describeBackup (PreviewableBackupSerializer) dry-run parses: counts '
        'rows, rejects wrong app + future schema, never writes', () async {
      await seedProfile('p1', 'Alice');
      await seedSession('s1', profileId: 'p1');
      await seedSession('s2', profileId: 'p1');
      final bytes = await serializer.dumpAll();

      expect(serializer, isA<PreviewableBackupSerializer>());
      final manifest = await serializer.describeBackup(bytes);
      expect(manifest.appId, 'sundial');
      expect(manifest.tableCounts['sessions'], 2);
      // Alice + the seeded default Everyone profile.
      expect(manifest.tableCounts['profiles'], 2);
      expect(manifest.createdAt, isNotNull);

      // Wrong app + future schema reject exactly like restoreAll would.
      final wrongApp = Uint8List.fromList(utf8.encode(jsonEncode(
          {'app': 'furrow', 'schemaVersion': 1, 'payload': <String, Object?>{}})));
      expect(() => serializer.describeBackup(wrongApp),
          throwsA(isA<FormatException>()));
      final tooNew = Uint8List.fromList(utf8.encode(jsonEncode({
        'app': 'sundial',
        'schemaVersion': 99,
        'payload': <String, Object?>{}
      })));
      expect(() => serializer.describeBackup(tooNew),
          throwsA(isA<BackupSchemaException>()));

      // REVIEW FIX: describe must reject payloads restoreAll would reject —
      // including a payload whose profiles key is not a List.
      final badPayload = Uint8List.fromList(utf8.encode(jsonEncode({
        'app': 'sundial',
        'schemaVersion': db.schemaVersion,
        'payload': {'profiles': 'not-a-list'},
      })));
      expect(() => serializer.describeBackup(badPayload),
          throwsA(isA<FormatException>()));

      // Dry-run guarantee: nothing was written by any of the above.
      expect(await db.select(db.sessions).get(), hasLength(2));
    });

    test('a LEGACY envelope without createdAt still restores', () async {
      await seedProfile('p1', 'Alice');
      await seedSession('s1', profileId: 'p1');
      final bytes = await serializer.dumpAll();
      final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      envelope.remove('createdAt'); // what pre-v2 Sundial builds wrote
      final legacy = Uint8List.fromList(utf8.encode(jsonEncode(envelope)));

      await db.delete(db.sessions).go();
      await db.delete(db.profiles).go();
      await serializer.restoreAll(legacy);
      expect(await db.select(db.sessions).get(), hasLength(1));
    });

    test('envelope carries app id and the DB schema version', () async {
      final bytes = await serializer.dumpAll();
      final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      expect(envelope['app'], 'sundial');
      expect(envelope['schemaVersion'], db.schemaVersion);
      expect(envelope['payload'], isA<Map<String, dynamic>>());
    });

    test('payload includes sessions, profiles, and earned badges', () async {
      await seedProfile('p1', 'Alice');
      await seedSession('s1', profileId: 'p1');
      await LocalBadgesRepository(BadgesDao(db), SessionsDao(db))
          .checkAndAwardMilestones();

      final bytes = await serializer.dumpAll();
      final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final payload = envelope['payload'] as Map<String, dynamic>;

      final profiles = payload['profiles'] as List<dynamic>;
      expect(profiles.any((p) => p['id'] == 'p1'), isTrue);

      final sessions = payload['sessions'] as List<dynamic>;
      expect(sessions.any((s) => s['id'] == 's1'), isTrue);
    });
  });

  group('restoreAll — round-trip', () {
    test('restores sessions, profiles, and earned badges into the same DB',
        () async {
      await seedProfile('p1', 'Alice');
      // 36000s = 10h, crossing the 10h milestone exactly.
      await seedSession('s1', profileId: 'p1', durationSecs: 36000);
      final badgesRepo = LocalBadgesRepository(BadgesDao(db), SessionsDao(db));
      await badgesRepo.checkAndAwardMilestones();

      final bytes = await serializer.dumpAll();
      await serializer.restoreAll(bytes);

      final profiles = await db.select(db.profiles).get();
      expect(profiles.any((p) => p.id == 'p1' && p.name == 'Alice'), isTrue);

      final sessions = await db.select(db.sessions).get();
      expect(sessions.any((s) => s.id == 's1'), isTrue);

      final badges = await db.select(db.badges).get();
      final earned = badges.where((b) => b.earnedAt != null).toList();
      expect(earned, isNotEmpty, reason: '10h badge should still be earned');
    });

    test('restoreAll is destructive: rows absent from the backup are gone',
        () async {
      await seedProfile('p1', 'Alice');
      await seedSession('s1', profileId: 'p1');
      final bytes = await serializer.dumpAll();

      // Add data AFTER the dump that must not survive restore.
      await seedProfile('p2', 'Bob');
      await seedSession('s2', profileId: 'p2');

      await serializer.restoreAll(bytes);

      final profiles = await db.select(db.profiles).get();
      expect(profiles.any((p) => p.id == 'p2'), isFalse,
          reason: 'profile added after the dump must be wiped by restore');

      final sessions = await db.select(db.sessions).get();
      expect(sessions.any((s) => s.id == 's2'), isFalse,
          reason: 'session added after the dump must be wiped by restore');
      expect(sessions.any((s) => s.id == 's1'), isTrue,
          reason: 'session present in the backup must be restored');
    });

    test('restores the annual goal (F10 — the single most important setting)',
        () async {
      await LocalSettingsRepository(db).setAnnualGoalHours(500);
      final bytes = await serializer.dumpAll();

      // Change the goal AFTER the dump — restore must bring back 500, not
      // silently keep (or default to) whatever is on-device now.
      await LocalSettingsRepository(db).setAnnualGoalHours(9999);

      await serializer.restoreAll(bytes);

      final prefs = await LocalSettingsRepository(db).getUserPrefs();
      expect(prefs.annualGoalHours, 500);
    });

    test(
        'badge catalog survives restore; a locally-earned badge absent from '
        'the backup ends up un-earned', () async {
      // Backup captured with ONLY the 10h badge earned.
      await seedSession('s_10h', durationSecs: 36000);
      final badgesRepo = LocalBadgesRepository(BadgesDao(db), SessionsDao(db));
      await badgesRepo.checkAndAwardMilestones();
      final beforeBackup = await db.select(db.badges).get();
      expect(beforeBackup.where((b) => b.earnedAt != null).map((b) => b.id),
          contains('badge_10h'));
      final bytes = await serializer.dumpAll();

      // Locally (post-dump) also earn the 25h badge — this must NOT survive
      // a restore from the earlier backup.
      await seedSession('s_more', profileId: null);
      await (db.update(db.badges)..where((t) => t.id.equals('badge_25h')))
          .write(const BadgesCompanion(earnedAt: Value(1700000999000)));

      await serializer.restoreAll(bytes);

      final restored = await db.select(db.badges).get();
      // Full catalog (16 seeded milestone badges) survives untouched.
      expect(restored, hasLength(16));
      final byId = {for (final b in restored) b.id: b};
      expect(byId['badge_10h']!.earnedAt, isNotNull,
          reason: 'badge present in the backup stays earned');
      expect(byId['badge_25h']!.earnedAt, isNull,
          reason: 'badge earned only after the dump must be un-earned');
      // Catalog thresholds are untouched by the destructive replace.
      expect(byId['badge_10h']!.thresholdHours, 10);
      expect(byId['badge_25h']!.thresholdHours, 25);
    });
  });

  group('restoreAll — rejection', () {
    test('rejects a backup made for a different app', () async {
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode({
        'app': 'lullaby',
        'schemaVersion': db.schemaVersion,
        'payload': {'version': 3, 'sessions': [], 'profiles': [], 'badges': []},
      })));

      expect(
        () => serializer.restoreAll(bytes),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a missing app field', () async {
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode({
        'schemaVersion': db.schemaVersion,
        'payload': {'version': 3, 'sessions': [], 'profiles': [], 'badges': []},
      })));

      expect(
        () => serializer.restoreAll(bytes),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a future schema version', () async {
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode({
        'app': 'sundial',
        'schemaVersion': db.schemaVersion + 999,
        'payload': {'version': 3, 'sessions': [], 'profiles': [], 'badges': []},
      })));

      expect(
        () => serializer.restoreAll(bytes),
        throwsA(isA<BackupSchemaException>()),
      );
    });

    test('rejects a missing schemaVersion', () async {
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode({
        'app': 'sundial',
        'payload': {'version': 3, 'sessions': [], 'profiles': [], 'badges': []},
      })));

      expect(
        () => serializer.restoreAll(bytes),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a missing payload', () async {
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode({
        'app': 'sundial',
        'schemaVersion': db.schemaVersion,
      })));

      expect(
        () => serializer.restoreAll(bytes),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects data that is not valid JSON', () async {
      final bytes = Uint8List.fromList(utf8.encode('not json'));

      expect(
        () => serializer.restoreAll(bytes),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
