// lib/features/badges/domain/badges_repository.dart
import 'package:sundial/core/storage/app_database.dart';

abstract interface class BadgesRepository {
  Stream<List<Badge>> watchAllBadges();
  /// Awards any newly crossed milestones. Returns newly awarded badges.
  Future<List<Badge>> checkAndAwardMilestones();

  /// Revokes any badges whose threshold is now above the current total hours.
  Future<void> revokeIfBelowMilestones();

  /// Restores earned badge state from a backup, keyed by badge id → earnedAt ms.
  /// Unknown ids are skipped (old backups that predate newer milestones still
  /// restore cleanly, and new backups on old installs skip unseeded rows).
  Future<void> restoreEarnedBadges(Map<String, int> earnedByIdMs);
}
