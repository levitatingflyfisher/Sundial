// lib/features/profiles/domain/profiles_repository.dart
import 'package:sundial/core/storage/app_database.dart';

/// What [ProfilesRepository.deleteProfile] removed: the row, and the ids of
/// the sessions whose link to it was cleared.
class DeletedProfile {
  const DeletedProfile({required this.profile, required this.sessionIds});
  final Profile profile;
  final List<String> sessionIds;
}

abstract class ProfilesRepository {
  Stream<List<Profile>> watchAll();
  Future<void> createProfile({required String name, String? emoji, required int colorValue});
  Future<void> updateProfile({required String id, required String name, String? emoji, required int colorValue});
  /// Deletes the profile and unlinks its sessions (they stay, as Everyone's).
  /// Returns what was taken, so [restoreProfile] can undo it exactly; null
  /// when no such profile existed.
  Future<DeletedProfile?> deleteProfile(String id);

  /// Undoes a [deleteProfile]: the row comes back as it was and exactly the
  /// sessions it owned are linked to it again.
  Future<void> restoreProfile(DeletedProfile deleted);

  /// Upserts a pre-built [ProfilesCompanion]. Used by JSON import to restore
  /// profiles with their original ids, timestamps, and sort order.
  Future<void> upsertRaw(ProfilesCompanion companion);
}
