// lib/features/profiles/data/local_profiles_repository.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/profiles/data/profiles_dao.dart';
import 'package:sundial/features/profiles/domain/profiles_repository.dart';
import 'package:sundial/features/sessions/data/sessions_dao.dart';

class LocalProfilesRepository implements ProfilesRepository {
  LocalProfilesRepository(this._dao, this._sessionsDao);
  final ProfilesDao _dao;
  final SessionsDao _sessionsDao;

  @override
  Stream<List<Profile>> watchAll() => _dao.watchAll();

  @override
  Future<void> createProfile({
    required String name,
    String? emoji,
    required int colorValue,
  }) async {
    final existing = await _dao.getAll();
    await _dao.upsert(ProfilesCompanion.insert(
      id: const Uuid().v4(),
      name: name,
      emoji: Value(emoji),
      colorValue: colorValue,
      sortOrder: Value(existing.length),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  @override
  Future<void> updateProfile({
    required String id,
    required String name,
    String? emoji,
    required int colorValue,
  }) async {
    await _dao.updateById(id, ProfilesCompanion(
      name: Value(name),
      emoji: Value(emoji),
      colorValue: Value(colorValue),
    ));
  }

  @override
  Future<DeletedProfile?> deleteProfile(String id) async {
    final profile =
        (await _dao.getAll()).where((p) => p.id == id).firstOrNull;
    if (profile == null) return null;
    final sessionIds = await _sessionsDao.sessionIdsForProfile(id);
    // Orphan sessions to no profile (null = "default" in queries).
    await _sessionsDao.clearProfileId(id);
    await _dao.deleteById(id);
    return DeletedProfile(profile: profile, sessionIds: sessionIds);
  }

  @override
  Future<void> restoreProfile(DeletedProfile deleted) async {
    await _dao.upsert(deleted.profile.toCompanion(true));
    if (deleted.sessionIds.isNotEmpty) {
      await _sessionsDao.setProfileId(deleted.sessionIds, deleted.profile.id);
    }
  }

  @override
  Future<void> upsertRaw(ProfilesCompanion companion) => _dao.upsert(companion);
}
