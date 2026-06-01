// lib/features/profiles/data/profiles_dao.dart
import 'package:drift/drift.dart';
import 'package:sundial/core/storage/app_database.dart';

part 'profiles_dao.g.dart';

@DriftAccessor(tables: [Profiles])
class ProfilesDao extends DatabaseAccessor<AppDatabase> with _$ProfilesDaoMixin {
  ProfilesDao(super.db);

  Stream<List<Profile>> watchAll() =>
      (select(profiles)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();

  Future<List<Profile>> getAll() => select(profiles).get();

  Future<void> upsert(ProfilesCompanion companion) =>
      into(profiles).insertOnConflictUpdate(companion);

  Future<void> updateById(String id, ProfilesCompanion companion) =>
      (update(profiles)..where((t) => t.id.equals(id))).write(companion);

  Future<int> deleteById(String id) =>
      (delete(profiles)..where((t) => t.id.equals(id))).go();
}
