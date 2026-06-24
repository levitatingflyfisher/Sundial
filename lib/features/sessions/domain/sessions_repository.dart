// lib/features/sessions/domain/sessions_repository.dart
import 'package:fpdart/fpdart.dart';
import 'package:sundial/core/error/failures.dart';
import 'package:sundial/core/storage/app_database.dart';

abstract interface class SessionsRepository {
  Stream<List<Session>> watchAllSessions();
  Stream<List<Session>> watchAllSessionsFiltered(String? profileId);
  Stream<List<Session>> watchSessionsForDay(String dateDay);
  Future<Either<StorageFailure, Unit>> saveSession(Session session);
  Future<Either<StorageFailure, Unit>> deleteSession(String id);
  Stream<int> watchSecondsForDay(String dateDay);
  Stream<int> watchSecondsForYearMonth(String yearMonth);
  Stream<int> watchSecondsForYear(String year);
  Stream<int> watchAllTimeSeconds();

  // Per-profile filtered variants. `null` = unfiltered (all profiles
  // combined). A non-null profileId selects that profile's own sessions
  // AND any null-profile (Everyone) sessions so shared time remains
  // visible from every member's view.
  Stream<int> watchSecondsForDayFiltered(String dateDay, String? profileId);
  Stream<int> watchSecondsForYearMonthFiltered(
    String yearMonth,
    String? profileId,
  );
  Stream<int> watchSecondsForYearFiltered(String year, String? profileId);
  Stream<int> watchAllTimeSecondsFiltered(String? profileId);
}
