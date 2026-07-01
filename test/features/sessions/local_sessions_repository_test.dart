// test/features/sessions/local_sessions_repository_test.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/sessions/data/local_sessions_repository.dart';
import 'package:sundial/features/sessions/data/sessions_dao.dart';

Session _makeSession({
  String id = 'session-1',
  int durationSecs = 3600,
  String dateDay = '2026-03-28',
  String? profileId,
}) {
  final parts = dateDay.split('-');
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final day = int.parse(parts[2]);
  final start = DateTime(year, month, day, 9);
  final end = DateTime(year, month, day, 10);
  final midnight = DateTime(year, month, day);
  return Session(
    id: id,
    startTime: start.millisecondsSinceEpoch,
    endTime: end.millisecondsSinceEpoch,
    durationSecs: durationSecs,
    notes: null,
    dateDay: dateDay,
    profileId: profileId,
    locationLabel: null,
    lat: null,
    lng: null,
    createdAt: midnight.millisecondsSinceEpoch,
    updatedAt: midnight.millisecondsSinceEpoch,
  );
}

void main() {
  late AppDatabase db;
  late LocalSessionsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LocalSessionsRepository(SessionsDao(db));
  });

  tearDown(() => db.close());

  group('LocalSessionsRepository', () {
    test('saveSession stores a session', () async {
      final session = _makeSession();
      final result = await repo.saveSession(session);
      expect(result.isRight(), isTrue);

      final sessions = await repo.watchAllSessions().first;
      expect(sessions.length, 1);
      expect(sessions.first.id, 'session-1');
    });

    test('saveSession is idempotent (upsert)', () async {
      final session = _makeSession();
      await repo.saveSession(session);
      // Update notes — use copyWith(notes: Value('updated note'))
      final updated = session.copyWith(notes: const Value('updated note'));
      await repo.saveSession(updated);

      final sessions = await repo.watchAllSessions().first;
      expect(sessions.length, 1);
      expect(sessions.first.notes, 'updated note');
    });

    test('deleteSession removes the session', () async {
      await repo.saveSession(_makeSession());
      final result = await repo.deleteSession('session-1');
      expect(result.isRight(), isTrue);

      final sessions = await repo.watchAllSessions().first;
      expect(sessions, isEmpty);
    });

    test('watchAllSessions returns in reverse chronological order', () async {
      await repo.saveSession(_makeSession(id: 'a', dateDay: '2026-03-26'));
      await repo.saveSession(_makeSession(id: 'b', dateDay: '2026-03-28'));
      final sessions = await repo.watchAllSessions().first;
      expect(sessions.first.id, 'b');
    });
  });

  // The 0 <= durationSecs <= 86400 invariant used to live only in three
  // presentation-layer checks (timer clamp, manual-entry, edit sheet); the
  // repository accepted any Session verbatim, so a corrupt or crafted
  // duration (e.g. from an imported backup) poisoned every SUM aggregate
  // and auto-awarded every hour-milestone badge. The repository boundary is
  // the single source of truth for the invariant.
  group('durationSecs invariant at the repository boundary', () {
    test('saveSession clamps an oversized duration to one day (86400s)',
        () async {
      final result =
          await repo.saveSession(_makeSession(durationSecs: 999999999));
      expect(result.isRight(), isTrue,
          reason: 'clamping is non-destructive — the save must still succeed');

      final rows = await db.select(db.sessions).get();
      expect(rows.single.durationSecs, 86400,
          reason: 'a stored duration must never exceed 24h — it would '
              'poison every aggregate and auto-award every badge');
    });

    test('saveSession clamps a negative duration to 0', () async {
      final result =
          await repo.saveSession(_makeSession(durationSecs: -50000));
      expect(result.isRight(), isTrue);

      final rows = await db.select(db.sessions).get();
      expect(rows.single.durationSecs, 0,
          reason: 'a negative stored duration would subtract from SUMs');
    });

    test('saveSession stores an in-range duration verbatim', () async {
      await repo.saveSession(_makeSession(durationSecs: 3600));
      final rows = await db.select(db.sessions).get();
      expect(rows.single.durationSecs, 3600);
    });
  });

  // Item 2 of the 2026-04-09 multi-profile completion plan.
  // Locks in the null-profile-counts-for-everyone semantic: a per-profile
  // view includes the profile's own sessions AND any sessions with
  // profileId=null (the shared Everyone bucket).
  group('per-profile filtered stat queries', () {
    setUp(() async {
      // Seed two named profiles so the FK constraint accepts the inserts.
      await db.into(db.profiles).insert(
            ProfilesCompanion.insert(
              id: 'dad',
              name: 'Dad',
              colorValue: 0xFF5E9478,
              createdAt: 0,
            ),
          );
      await db.into(db.profiles).insert(
            ProfilesCompanion.insert(
              id: 'mom',
              name: 'Mom',
              colorValue: 0xFFD98F5E,
              createdAt: 0,
            ),
          );

      // Sessions on 2026-03-28:
      //   S1 dad     — 1h
      //   S2 mom     — 2h
      //   S3 null    — 30m (Everyone / shared)
      await repo.saveSession(_makeSession(
        id: 's1',
        profileId: 'dad',
        durationSecs: 3600,
      ));
      await repo.saveSession(_makeSession(
        id: 's2',
        profileId: 'mom',
        durationSecs: 7200,
      ));
      await repo.saveSession(_makeSession(
        id: 's3',
        profileId: null,
        durationSecs: 1800,
      ));
    });

    test('watchSecondsForDayFiltered(null) sums all sessions', () async {
      final total =
          await repo.watchSecondsForDayFiltered('2026-03-28', null).first;
      expect(total, 3600 + 7200 + 1800); // 3.5h
    });

    test('watchSecondsForDayFiltered("dad") sums dad + everyone sessions',
        () async {
      final total =
          await repo.watchSecondsForDayFiltered('2026-03-28', 'dad').first;
      expect(total, 3600 + 1800,
          reason: 'per-profile day view must include null-profile '
              'Everyone sessions — otherwise shared time disappears from '
              "each member's view");
    });

    test(
        'watchSecondsForYearMonthFiltered("2026-03", "mom") '
        'sums mom + everyone', () async {
      final total = await repo
          .watchSecondsForYearMonthFiltered('2026-03', 'mom')
          .first;
      expect(total, 7200 + 1800);
    });

    test('watchSecondsForYearFiltered("2026", null) sums all', () async {
      final total =
          await repo.watchSecondsForYearFiltered('2026', null).first;
      expect(total, 3600 + 7200 + 1800);
    });

    test(
        'watchAllTimeSecondsFiltered("dad") includes null-profile sessions',
        () async {
      final total = await repo.watchAllTimeSecondsFiltered('dad').first;
      expect(total, 3600 + 1800,
          reason: 'all-time per-profile total must count shared sessions');
    });
  });
}
