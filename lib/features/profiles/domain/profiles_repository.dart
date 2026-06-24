// lib/features/profiles/domain/profiles_repository.dart
import 'package:sundial/core/storage/app_database.dart';

abstract class ProfilesRepository {
  Stream<List<Profile>> watchAll();
  Future<void> createProfile({required String name, String? emoji, required int colorValue});
  Future<void> updateProfile({required String id, required String name, String? emoji, required int colorValue});
  Future<void> deleteProfile(String id);

  /// Upserts a pre-built [ProfilesCompanion]. Used by JSON import to restore
  /// profiles with their original ids, timestamps, and sort order.
  Future<void> upsertRaw(ProfilesCompanion companion);
}
