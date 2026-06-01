import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/badges/data/badges_dao.dart';
import 'package:sundial/features/badges/data/local_badges_repository.dart';
import 'package:sundial/features/sessions/data/sessions_dao.dart';
import 'package:sundial/features/sessions/data/local_sessions_repository.dart';

Session _makeSession(String id, int durationSecs, String day) => Session(
  id: id,
  startTime: 0,
  endTime: durationSecs * 1000,
  durationSecs: durationSecs,
  notes: null,
  dateDay: day,
  locationLabel: null,
  lat: null,
  lng: null,
  createdAt: 0,
  updatedAt: 0,
);

void main() {
  late AppDatabase db;
  late LocalBadgesRepository badgesRepo;
  late LocalSessionsRepository sessionsRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    badgesRepo = LocalBadgesRepository(BadgesDao(db), SessionsDao(db));
    sessionsRepo = LocalSessionsRepository(SessionsDao(db));
  });

  tearDown(() => db.close());

  group('LocalBadgesRepository', () {
    test('badges are seeded and unearned on first open', () async {
      final badges = await badgesRepo.watchAllBadges().first;
      expect(badges.isNotEmpty, isTrue);
      expect(badges.every((b) => b.earnedAt == null), isTrue);
    });

    test('checkAndAwardMilestones awards 10h badge when total >= 10h', () async {
      // 36001 seconds = 10h + 1s
      await sessionsRepo.saveSession(_makeSession('s1', 36001, '2026-03-28'));
      final awarded = await badgesRepo.checkAndAwardMilestones();
      expect(awarded.any((b) => b.thresholdHours == 10), isTrue);
    });

    test('does not re-award already-earned badge', () async {
      await sessionsRepo.saveSession(_makeSession('s1', 36001, '2026-03-28'));
      await badgesRepo.checkAndAwardMilestones();
      final second = await badgesRepo.checkAndAwardMilestones();
      expect(second, isEmpty);
      final badges = await badgesRepo.watchAllBadges().first;
      final tenHour = badges.where((b) => b.thresholdHours == 10);
      expect(tenHour.length, 1);
    });

    test('does not award badge when total is below threshold', () async {
      await sessionsRepo.saveSession(_makeSession('s1', 1800, '2026-03-28')); // 30 min
      final awarded = await badgesRepo.checkAndAwardMilestones();
      expect(awarded, isEmpty);
    });
  });
}
