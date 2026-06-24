// lib/features/sessions/data/local_sessions_repository.dart
import 'package:fpdart/fpdart.dart';
import 'package:sundial/core/error/failures.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/sessions/domain/sessions_repository.dart';
import 'sessions_dao.dart';

class LocalSessionsRepository implements SessionsRepository {
  LocalSessionsRepository(this._dao);
  final SessionsDao _dao;

  @override
  Stream<List<Session>> watchAllSessions() => _dao.watchAll();

  @override
  Stream<List<Session>> watchAllSessionsFiltered(String? profileId) =>
      _dao.watchAllFiltered(profileId);

  @override
  Stream<List<Session>> watchSessionsForDay(String dateDay) =>
      _dao.watchForDay(dateDay);

  @override
  Future<Either<StorageFailure, Unit>> saveSession(Session session) async {
    try {
      await _dao.upsert(session.toCompanion(true));
      return right(unit);
    } catch (e) {
      return left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<StorageFailure, Unit>> deleteSession(String id) async {
    try {
      await _dao.deleteById(id);
      return right(unit);
    } catch (e) {
      return left(StorageFailure(e.toString()));
    }
  }

  @override
  Stream<int> watchSecondsForDay(String dateDay) =>
      _dao.watchSecondsForDay(dateDay);

  @override
  Stream<int> watchSecondsForYearMonth(String yearMonth) =>
      _dao.watchSecondsForYearMonth(yearMonth);

  @override
  Stream<int> watchSecondsForYear(String year) =>
      _dao.watchSecondsForYear(year);

  @override
  Stream<int> watchAllTimeSeconds() => _dao.watchAllTimeSeconds();

  @override
  Stream<int> watchSecondsForDayFiltered(
    String dateDay,
    String? profileId,
  ) =>
      _dao.watchSecondsForDayFiltered(dateDay, profileId);

  @override
  Stream<int> watchSecondsForYearMonthFiltered(
    String yearMonth,
    String? profileId,
  ) =>
      _dao.watchSecondsForYearMonthFiltered(yearMonth, profileId);

  @override
  Stream<int> watchSecondsForYearFiltered(
    String year,
    String? profileId,
  ) =>
      _dao.watchSecondsForYearFiltered(year, profileId);

  @override
  Stream<int> watchAllTimeSecondsFiltered(String? profileId) =>
      _dao.watchAllTimeSecondsFiltered(profileId);
}
