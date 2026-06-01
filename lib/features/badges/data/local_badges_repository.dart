// lib/features/badges/data/local_badges_repository.dart
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/badges/data/badges_dao.dart';
import 'package:sundial/features/badges/domain/badges_repository.dart';
import 'package:sundial/features/sessions/data/sessions_dao.dart';

class LocalBadgesRepository implements BadgesRepository {
  LocalBadgesRepository(this._badgesDao, this._sessionsDao);
  final BadgesDao _badgesDao;
  final SessionsDao _sessionsDao;

  @override
  Stream<List<Badge>> watchAllBadges() => _badgesDao.watchAll();

  @override
  Future<List<Badge>> checkAndAwardMilestones() async {
    final totalSecs = await _sessionsDao.watchAllTimeSeconds().first;
    final totalHours = totalSecs ~/ 3600;

    final allBadges = await _badgesDao.getAll();
    final newlyAwarded = <Badge>[];
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final badge in allBadges) {
      if (badge.earnedAt == null && totalHours >= badge.thresholdHours) {
        await _badgesDao.markEarned(badge.id, now);
        newlyAwarded.add(badge);
      }
    }

    return newlyAwarded;
  }

  @override
  Future<void> revokeIfBelowMilestones() async {
    final totalSecs = await _sessionsDao.watchAllTimeSeconds().first;
    final totalHours = totalSecs ~/ 3600;
    final allBadges = await _badgesDao.getAll();
    for (final badge in allBadges) {
      if (badge.earnedAt != null && badge.thresholdHours > totalHours) {
        await _badgesDao.markRevoked(badge.id);
      }
    }
  }

  @override
  Future<void> restoreEarnedBadges(Map<String, int> earnedByIdMs) async {
    final known = {for (final b in await _badgesDao.getAll()) b.id};
    for (final entry in earnedByIdMs.entries) {
      if (!known.contains(entry.key)) continue;
      await _badgesDao.markEarned(entry.key, entry.value);
    }
  }
}
