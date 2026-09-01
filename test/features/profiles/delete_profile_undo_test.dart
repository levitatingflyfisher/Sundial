import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/profiles/data/local_profiles_repository.dart';
import 'package:sundial/features/profiles/data/profiles_dao.dart';
import 'package:sundial/features/sessions/data/sessions_dao.dart';

/// Removing a person is a deliberate tap, so under the fleet delete ruling
/// it happens at once and offers Undo. Undo must put back exactly what the
/// delete took: the profile row and the link on each of their sessions, and
/// no link on sessions that never belonged to them.
void main() {
  late AppDatabase db;
  late LocalProfilesRepository repo;

  Future<void> addSession(String id, String? profileId) =>
      SessionsDao(db).upsert(SessionsCompanion.insert(
        id: id,
        startTime: 0,
        endTime: 3600000,
        durationSecs: 3600,
        dateDay: '2026-09-01',
        profileId: Value(profileId),
        createdAt: 0,
        updatedAt: 0,
      ));

  Future<String?> ownerOf(String id) async =>
      (await SessionsDao(db).watchAll().first)
          .firstWhere((s) => s.id == id)
          .profileId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = LocalProfilesRepository(ProfilesDao(db), SessionsDao(db));
    await repo.createProfile(name: 'Dad', colorValue: 0xFF00FF00);
  });
  tearDown(() => db.close());

  test('undo restores the profile and re-links exactly their sessions',
      () async {
    final dad =
        (await ProfilesDao(db).getAll()).firstWhere((p) => p.name == 'Dad');
    await addSession('dad-1', dad.id);
    await addSession('dad-2', dad.id);
    await addSession('shared', null);
    await addSession('me-1', 'default');

    final deleted = await repo.deleteProfile(dad.id);

    expect((await ProfilesDao(db).getAll()).any((p) => p.id == dad.id),
        isFalse);
    expect(await ownerOf('dad-1'), isNull);

    await repo.restoreProfile(deleted!);

    final restored =
        (await ProfilesDao(db).getAll()).firstWhere((p) => p.id == dad.id);
    expect(restored, dad, reason: 'name, colour, order and createdAt intact');
    expect(await ownerOf('dad-1'), dad.id);
    expect(await ownerOf('dad-2'), dad.id);
    expect(await ownerOf('shared'), isNull,
        reason: 'a session that was never theirs must not be claimed');
    expect(await ownerOf('me-1'), 'default');
  });

  test('deleting a profile that does not exist returns null', () async {
    expect(await repo.deleteProfile('nobody'), isNull);
  });
}
