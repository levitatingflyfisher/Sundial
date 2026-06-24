// lib/features/sessions/data/sessions_dao.dart
import 'package:drift/drift.dart';
import 'package:sundial/core/storage/app_database.dart';

part 'sessions_dao.g.dart';

@DriftAccessor(tables: [Sessions])
class SessionsDao extends DatabaseAccessor<AppDatabase>
    with _$SessionsDaoMixin {
  SessionsDao(super.db);

  Stream<List<Session>> watchAll() =>
      (select(sessions)
            ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
          .watch();

  Future<void> upsert(SessionsCompanion companion) =>
      into(sessions).insertOnConflictUpdate(companion);

  Future<int> deleteById(String id) =>
      (delete(sessions)..where((t) => t.id.equals(id))).go();

  Stream<int> watchSecondsForDay(String dateDay) {
    final s = sessions.durationSecs.sum();
    return (selectOnly(sessions)
          ..addColumns([s])
          ..where(sessions.dateDay.equals(dateDay)))
        .map((r) => r.read(s) ?? 0)
        .watchSingle();
  }

  Stream<int> watchSecondsForYearMonth(String yearMonth) {
    final s = sessions.durationSecs.sum();
    return (selectOnly(sessions)
          ..addColumns([s])
          ..where(sessions.dateDay.like('$yearMonth%')))
        .map((r) => r.read(s) ?? 0)
        .watchSingle();
  }

  Stream<int> watchSecondsForYear(String year) {
    final s = sessions.durationSecs.sum();
    return (selectOnly(sessions)
          ..addColumns([s])
          ..where(sessions.dateDay.like('$year%')))
        .map((r) => r.read(s) ?? 0)
        .watchSingle();
  }

  Stream<int> watchAllTimeSeconds() {
    final s = sessions.durationSecs.sum();
    return (selectOnly(sessions)..addColumns([s]))
        .map((r) => r.read(s) ?? 0)
        .watchSingle();
  }

  Stream<List<Session>> watchForDay(String dateDay) =>
      (select(sessions)..where((t) => t.dateDay.equals(dateDay))).watch();

  /// Returns sessions for [profileId], or all sessions when [profileId] is null.
  Stream<List<Session>> watchAllFiltered(String? profileId) {
    if (profileId == null) return watchAll();
    return (select(sessions)
          ..where((t) => t.profileId.equals(profileId) | t.profileId.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
        .watch();
  }

  /// Profile-filtered seconds for a day. null = all profiles combined.
  Stream<int> watchSecondsForDayFiltered(String dateDay, String? profileId) {
    final s = sessions.durationSecs.sum();
    final q = selectOnly(sessions)
      ..addColumns([s])
      ..where(sessions.dateDay.equals(dateDay));
    if (profileId != null) {
      q.where(sessions.profileId.equals(profileId) | sessions.profileId.isNull());
    }
    return q.map((r) => r.read(s) ?? 0).watchSingle();
  }

  /// Profile-filtered seconds for a year-month (e.g. '2026-03'). null = all
  /// profiles combined. A per-profile view also includes null-profile
  /// (Everyone) sessions so shared time is visible from every member's view.
  Stream<int> watchSecondsForYearMonthFiltered(
    String yearMonth,
    String? profileId,
  ) {
    final s = sessions.durationSecs.sum();
    final q = selectOnly(sessions)
      ..addColumns([s])
      ..where(sessions.dateDay.like('$yearMonth%'));
    if (profileId != null) {
      q.where(sessions.profileId.equals(profileId) | sessions.profileId.isNull());
    }
    return q.map((r) => r.read(s) ?? 0).watchSingle();
  }

  /// Profile-filtered seconds for a year. null = all profiles combined.
  Stream<int> watchSecondsForYearFiltered(String year, String? profileId) {
    final s = sessions.durationSecs.sum();
    final q = selectOnly(sessions)
      ..addColumns([s])
      ..where(sessions.dateDay.like('$year%'));
    if (profileId != null) {
      q.where(sessions.profileId.equals(profileId) | sessions.profileId.isNull());
    }
    return q.map((r) => r.read(s) ?? 0).watchSingle();
  }

  /// Profile-filtered all-time seconds. null = all profiles combined.
  Stream<int> watchAllTimeSecondsFiltered(String? profileId) {
    final s = sessions.durationSecs.sum();
    final q = selectOnly(sessions)..addColumns([s]);
    if (profileId != null) {
      q.where(sessions.profileId.equals(profileId) | sessions.profileId.isNull());
    }
    return q.map((r) => r.read(s) ?? 0).watchSingle();
  }

  Future<void> clearProfileId(String profileId) => (update(sessions)
        ..where((t) => t.profileId.equals(profileId)))
      .write(const SessionsCompanion(profileId: Value(null)));
}
