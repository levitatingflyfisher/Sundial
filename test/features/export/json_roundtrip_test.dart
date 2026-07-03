// Round-trip tests for the JSON backup/restore path.
//
// These tests exist because import runs against a user's live database. Even
// though the import path is upsert-only (no deletes), a silent schema drift
// between JsonExporter and JsonImporter could overwrite real data with
// partially-parsed rows. The tests assert:
//
//   1. A v3 backup round-trips exactly (sessions, profiles, badges).
//   2. Null-profile "Everyone" sessions stay null after round-trip.
//   3. v1 and v2 payloads still parse into the current model.
//   4. Import is non-destructive: applying a backup onto a DB that already
//      contains data preserves the pre-existing rows.
//
// The "drag the real backup into this test" note at the bottom of the file
// tells you how to run your own data through it without touching the app.

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/badges/data/badges_dao.dart';
import 'package:sundial/features/badges/data/local_badges_repository.dart';
import 'package:sundial/features/export/data/json_export_impl.dart';
import 'package:sundial/features/export/data/json_import_impl.dart';
import 'package:sundial/features/profiles/data/local_profiles_repository.dart';
import 'package:sundial/features/profiles/data/profiles_dao.dart';
import 'package:sundial/features/sessions/data/local_sessions_repository.dart';
import 'package:sundial/features/sessions/data/sessions_dao.dart';

Session _sess({
  required String id,
  required String day,
  required int durationSecs,
  String? profileId,
  String? notes,
  int startMs = 0,
}) =>
    Session(
      id: id,
      startTime: startMs,
      endTime: startMs + durationSecs * 1000,
      durationSecs: durationSecs,
      dateDay: day,
      profileId: profileId,
      notes: notes,
      locationLabel: null,
      lat: null,
      lng: null,
      createdAt: startMs,
      updatedAt: startMs,
    );

Profile _profile({
  required String id,
  required String name,
  String? emoji,
  int colorValue = 0xFF5E9478,
  int sortOrder = 0,
  int createdAt = 1700000000000,
}) =>
    Profile(
      id: id,
      name: name,
      emoji: emoji,
      colorValue: colorValue,
      sortOrder: sortOrder,
      createdAt: createdAt,
    );

void main() {
  // Intentionally opening multiple AppDatabase instances (one source + one
  // target per round-trip test). Both are in-memory SQLite, so there's no
  // shared executor and no race risk.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('JsonExporter/JsonImporter — pure round-trip', () {
    final exporter = JsonExporter();
    final importer = JsonImporter();

    test('v3: sessions, profiles, and badges round-trip unchanged', () {
      final profiles = [
        _profile(id: 'p1', name: 'Alice', emoji: '🌱', colorValue: 0xFF5E9478),
        _profile(id: 'p2', name: 'Bob', colorValue: 0xFFD48B44, sortOrder: 1),
      ];
      final sessions = [
        _sess(id: 's1', day: '2026-04-01', durationSecs: 3600, profileId: 'p1'),
        _sess(id: 's2', day: '2026-04-01', durationSecs: 1800, profileId: 'p2'),
        _sess(id: 's3', day: '2026-04-02', durationSecs: 7200, notes: 'hike'),
      ];
      final badges = [
        Badge(id: 'badge_10h', thresholdHours: 10, earnedAt: 1700000000000),
        Badge(id: 'badge_25h', thresholdHours: 25, earnedAt: null),
        Badge(id: 'badge_50h', thresholdHours: 50, earnedAt: 1700000500000),
      ];

      final json = exporter.buildJson(
        sessions,
        annualGoalHours: 1000,
        profiles: profiles,
        badges: badges,
      );

      final parsed = importer.parse(json);

      // Sessions round-trip exactly.
      expect(parsed.sessions.length, sessions.length);
      for (var i = 0; i < sessions.length; i++) {
        final orig = sessions[i];
        final restored = parsed.sessions[i];
        expect(restored.id, orig.id);
        expect(restored.startTime, orig.startTime);
        expect(restored.endTime, orig.endTime);
        expect(restored.durationSecs, orig.durationSecs);
        expect(restored.dateDay, orig.dateDay);
        expect(restored.profileId, orig.profileId);
        expect(restored.notes, orig.notes);
      }

      // Profiles round-trip exactly (via their companion representation).
      expect(parsed.profiles.length, profiles.length);
      for (var i = 0; i < profiles.length; i++) {
        final orig = profiles[i];
        final restored = parsed.profiles[i];
        expect(restored.id.value, orig.id);
        expect(restored.name.value, orig.name);
        expect(restored.emoji.value, orig.emoji);
        expect(restored.colorValue.value, orig.colorValue);
        expect(restored.sortOrder.value, orig.sortOrder);
        expect(restored.createdAt.value, orig.createdAt);
      }

      // Only earned badges are exported. Unearned rows are skipped because
      // they're already seeded on any install.
      expect(parsed.earnedBadges.length, 2);
      expect(parsed.earnedBadges['badge_10h'], 1700000000000);
      expect(parsed.earnedBadges['badge_50h'], 1700000500000);
      expect(parsed.earnedBadges.containsKey('badge_25h'), isFalse);
    });

    test('null-profile "Everyone" sessions stay null after round-trip', () {
      final sessions = [
        _sess(id: 'e1', day: '2026-04-03', durationSecs: 3600, profileId: null),
      ];
      final json =
          exporter.buildJson(sessions, annualGoalHours: 1000, profiles: []);

      final parsed = importer.parse(json);
      expect(parsed.sessions.single.profileId, isNull);
    });

    test('empty export parses back to empty payload', () {
      final json = exporter.buildJson(const [], annualGoalHours: 1000);
      final parsed = importer.parse(json);
      expect(parsed.sessions, isEmpty);
      expect(parsed.profiles, isEmpty);
      expect(parsed.earnedBadges, isEmpty);
    });
  });

  group('JsonImporter — backward compatibility', () {
    final importer = JsonImporter();

    test('v1 (no profiles, no badges) parses cleanly', () {
      // Hand-crafted v1 payload as the old exporter would have written it.
      const v1 = '{'
          '"version":1,'
          '"exported":"2025-12-01T00:00:00.000",'
          '"annual_goal_hours":500,'
          '"sessions":['
          '{"id":"s1","start_time":0,"end_time":3600000,'
          '"duration_secs":3600,"date_day":"2025-11-30",'
          '"created_at":0,"updated_at":0}'
          ']'
          '}';

      final parsed = importer.parse(v1);
      expect(parsed.sessions, hasLength(1));
      // v1 had no profile column — importer must null it out.
      expect(parsed.sessions.single.profileId, isNull);
      expect(parsed.profiles, isEmpty);
      expect(parsed.earnedBadges, isEmpty);
    });

    test('skips a malformed session row instead of aborting the import', () {
      // One good row, one missing the required duration_secs. A foreign or
      // partial export must not abort the whole import with a type error.
      const payload = '{'
          '"version":2,'
          '"sessions":['
          '{"id":"good","start_time":0,"end_time":3600000,'
          '"duration_secs":3600,"date_day":"2026-01-15",'
          '"created_at":0,"updated_at":0},'
          '{"id":"bad","start_time":0,"end_time":3600000,'
          '"date_day":"2026-01-16","created_at":0,"updated_at":0}'
          ']'
          '}';
      final parsed = importer.parse(payload);
      expect(parsed.sessions, hasLength(1),
          reason: 'the row missing duration_secs must be skipped, not throw');
      expect(parsed.sessions.single.id, 'good');
    });

    test('clamps an out-of-range imported duration to [0, 86400]', () {
      const payload = '{'
          '"version":2,'
          '"sessions":['
          '{"id":"huge","start_time":0,"end_time":90000000,'
          '"duration_secs":999999,"date_day":"2026-01-15",'
          '"created_at":0,"updated_at":0}'
          ']'
          '}';
      final parsed = importer.parse(payload);
      expect(parsed.sessions.single.durationSecs, 86400);
    });

    test('v2 (profiles, no badges) parses cleanly with profile attribution', () {
      const v2 = '{'
          '"version":2,'
          '"exported":"2026-02-01T00:00:00.000",'
          '"annual_goal_hours":1000,'
          '"profiles":['
          '{"id":"p1","name":"Alice","color_value":6199928,'
          '"sort_order":0,"created_at":0}'
          '],'
          '"sessions":['
          '{"id":"s1","start_time":0,"end_time":3600000,'
          '"duration_secs":3600,"date_day":"2026-01-15",'
          '"profile_id":"p1","created_at":0,"updated_at":0}'
          ']'
          '}';

      final parsed = importer.parse(v2);
      expect(parsed.sessions, hasLength(1));
      expect(parsed.sessions.single.profileId, 'p1');
      expect(parsed.profiles, hasLength(1));
      expect(parsed.profiles.single.id.value, 'p1');
      expect(parsed.profiles.single.name.value, 'Alice');
      expect(parsed.earnedBadges, isEmpty);
    });

    test('missing version field defaults to v1 semantics', () {
      // An older or hand-written payload with no version key should still
      // parse as the most conservative format (no profile attribution).
      const noVersion = '{'
          '"sessions":['
          '{"id":"s1","start_time":0,"end_time":3600000,'
          '"duration_secs":3600,"date_day":"2025-11-30",'
          '"profile_id":"p1","created_at":0,"updated_at":0}'
          ']'
          '}';

      final parsed = importer.parse(noVersion);
      // profile_id is present in the payload but v1 rules say ignore it.
      expect(parsed.sessions.single.profileId, isNull);
    });
  });

  group('End-to-end round-trip through real repositories', () {
    late AppDatabase db;
    late LocalSessionsRepository sessionsRepo;
    late LocalProfilesRepository profilesRepo;
    late LocalBadgesRepository badgesRepo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      sessionsRepo = LocalSessionsRepository(SessionsDao(db));
      profilesRepo = LocalProfilesRepository(ProfilesDao(db), SessionsDao(db));
      badgesRepo = LocalBadgesRepository(BadgesDao(db), SessionsDao(db));
    });

    tearDown(() => db.close());

    Future<AppDatabase> freshDb() async => AppDatabase(NativeDatabase.memory());

    test('full DB export → import into a fresh DB reproduces all data',
        () async {
      // ── Populate source DB ──
      await profilesRepo.upsertRaw(ProfilesCompanion(
        id: const Value('p1'),
        name: const Value('Alice'),
        emoji: const Value('🌱'),
        colorValue: const Value(0xFF5E9478),
        sortOrder: const Value(0),
        createdAt: const Value(1700000000000),
      ));
      await profilesRepo.upsertRaw(ProfilesCompanion(
        id: const Value('p2'),
        name: const Value('Bob'),
        emoji: const Value.absent(),
        colorValue: const Value(0xFFD48B44),
        sortOrder: const Value(1),
        createdAt: const Value(1700000100000),
      ));
      await sessionsRepo.saveSession(_sess(
          id: 's1',
          day: '2026-04-01',
          durationSecs: 36001,
          profileId: 'p1'));
      await sessionsRepo.saveSession(
          _sess(id: 's2', day: '2026-04-02', durationSecs: 1800, profileId: 'p2'));
      await sessionsRepo.saveSession(
          _sess(id: 's3', day: '2026-04-03', durationSecs: 3600, profileId: null));
      // Award the 10h badge (s1 alone is > 10h).
      await badgesRepo.checkAndAwardMilestones();

      // ── Export ──
      final sessions = await sessionsRepo.watchAllSessions().first;
      final profiles = await profilesRepo.watchAll().first;
      final badges = await badgesRepo.watchAllBadges().first;
      final earnedBefore = badges.where((b) => b.earnedAt != null).toList();
      expect(earnedBefore, isNotEmpty,
          reason: '10h badge should have been awarded');

      final json = JsonExporter().buildJson(
        sessions,
        annualGoalHours: 1000,
        profiles: profiles,
        badges: badges,
      );

      // ── Import into a fresh target DB ──
      final target = await freshDb();
      addTearDown(target.close);
      final targetProfiles =
          LocalProfilesRepository(ProfilesDao(target), SessionsDao(target));
      final targetSessions = LocalSessionsRepository(SessionsDao(target));
      final targetBadges =
          LocalBadgesRepository(BadgesDao(target), SessionsDao(target));

      final payload = JsonImporter().parse(json);
      for (final p in payload.profiles) {
        await targetProfiles.upsertRaw(p);
      }
      for (final s in payload.sessions) {
        await targetSessions.saveSession(s);
      }
      await targetBadges.restoreEarnedBadges(payload.earnedBadges);

      // ── Verify target matches source ──
      final restoredSessions = await targetSessions.watchAllSessions().first;
      expect(restoredSessions.length, sessions.length);

      final sourceById = {for (final s in sessions) s.id: s};
      for (final restored in restoredSessions) {
        final orig = sourceById[restored.id]!;
        expect(restored.profileId, orig.profileId,
            reason: 'profileId preserved for ${restored.id}');
        expect(restored.durationSecs, orig.durationSecs);
        expect(restored.dateDay, orig.dateDay);
        expect(restored.startTime, orig.startTime);
        expect(restored.endTime, orig.endTime);
      }

      // Null-profile session survived.
      expect(
        restoredSessions.where((s) => s.profileId == null).length,
        1,
        reason: 'Everyone session should stay null-profile',
      );

      // Profiles restored with exact fields. Note both source and target DBs
      // auto-seed a 'default' profile via the onCreate migration, so counts
      // include it on both sides.
      final restoredProfiles = await targetProfiles.watchAll().first;
      expect(restoredProfiles.length, profiles.length,
          reason: 'restored profile count should match source exactly');
      final restoredById = {for (final p in restoredProfiles) p.id: p};
      expect(restoredById['p1']!.name, 'Alice');
      expect(restoredById['p1']!.emoji, '🌱');
      expect(restoredById['p1']!.colorValue, 0xFF5E9478);
      expect(restoredById['p2']!.name, 'Bob');
      expect(restoredById['p2']!.emoji, isNull);
      expect(restoredById.containsKey('default'), isTrue,
          reason: 'seeded default profile survives round-trip');

      // Earned badges restored with their exact earnedAt timestamps.
      final restoredBadges = await targetBadges.watchAllBadges().first;
      final restoredEarned =
          restoredBadges.where((b) => b.earnedAt != null).toList();
      expect(restoredEarned.length, earnedBefore.length);
      for (final b in earnedBefore) {
        final match = restoredBadges.firstWhere((r) => r.id == b.id);
        expect(match.earnedAt, b.earnedAt,
            reason: 'earnedAt preserved for ${b.id}');
      }
    });

    test('import is non-destructive: existing rows stay when new ones land',
        () async {
      // Pre-existing row in the target DB — must survive the import.
      await sessionsRepo.saveSession(_sess(
        id: 'pre_existing',
        day: '2026-03-15',
        durationSecs: 1800,
        notes: 'do not lose me',
      ));

      // Build a backup that has different session ids.
      final backupJson = JsonExporter().buildJson(
        [
          _sess(id: 'from_backup_1', day: '2026-04-01', durationSecs: 3600),
          _sess(id: 'from_backup_2', day: '2026-04-02', durationSecs: 7200),
        ],
        annualGoalHours: 1000,
      );

      // Import into the SAME db that already has pre_existing.
      final payload = JsonImporter().parse(backupJson);
      for (final s in payload.sessions) {
        await sessionsRepo.saveSession(s);
      }

      final all = await sessionsRepo.watchAllSessions().first;
      expect(all.length, 3, reason: 'all three rows should coexist');
      expect(all.any((s) => s.id == 'pre_existing'), isTrue,
          reason: 'pre-existing row must survive non-destructive import');
      expect(all.any((s) => s.id == 'from_backup_1'), isTrue);
      expect(all.any((s) => s.id == 'from_backup_2'), isTrue);

      // And the pre-existing row's fields are untouched.
      final survivor = all.firstWhere((s) => s.id == 'pre_existing');
      expect(survivor.notes, 'do not lose me');
      expect(survivor.durationSecs, 1800);
    });

    test(
      'importing a backup that shares IDs with existing rows upserts — never drops',
      () async {
        // Pre-existing row.
        await sessionsRepo.saveSession(_sess(
          id: 'shared_id',
          day: '2026-03-15',
          durationSecs: 1800,
          notes: 'old version',
        ));

        // Backup has the same id but different fields — upsert should
        // replace the fields but the row must still exist afterwards.
        final backupJson = JsonExporter().buildJson(
          [
            _sess(
                id: 'shared_id',
                day: '2026-03-15',
                durationSecs: 3600,
                notes: 'restored version'),
          ],
          annualGoalHours: 1000,
        );

        final payload = JsonImporter().parse(backupJson);
        for (final s in payload.sessions) {
          await sessionsRepo.saveSession(s);
        }

        final all = await sessionsRepo.watchAllSessions().first;
        expect(all.length, 1);
        expect(all.single.id, 'shared_id');
        expect(all.single.notes, 'restored version',
            reason: 'upsert should overwrite fields');
        expect(all.single.durationSecs, 3600);
      },
    );
  });
}

// ── How to test your own real backup without touching the app ────────────
//
// 1. In the app: Settings → Backup & Restore → JSON → Save to device
// 2. adb pull the resulting sundial-backup.json to your dev machine
// 3. Add a one-off test below that loads that file and asserts import works:
//
//    test('my real backup parses', () async {
//      final content = await File('/path/to/sundial-backup.json').readAsString();
//      final parsed = JsonImporter().parse(content);
//      expect(parsed.sessions, isNotEmpty);
//      // etc.
//    });
//
// 4. Run: flutter test test/features/export/json_roundtrip_test.dart
//
// This never touches your device's DB and gives you a green/red light on
// whether the backup is internally consistent before you ever hit "Import".
