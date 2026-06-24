import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/profiles/data/local_profiles_repository.dart';
import 'package:sundial/features/profiles/data/profiles_dao.dart';
import 'package:sundial/features/sessions/data/sessions_dao.dart';

void main() {
  test('updateProfile preserves createdAt and sortOrder', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = LocalProfilesRepository(ProfilesDao(db), SessionsDao(db));

    // The DB seeds a default 'Me' profile. Use it as the test subject —
    // this mirrors the exact bug: editing the *default* profile's emoji fails.
    final allBefore = await ProfilesDao(db).getAll();
    final before = allBefore.firstWhere((p) => p.id == 'default');
    expect(before.name, 'Me');
    expect(before.createdAt, isNonZero);

    // Update only the emoji on the default profile.
    await repo.updateProfile(
      id: before.id,
      name: 'Me',
      emoji: '\u{1F33B}',
      colorValue: before.colorValue,
    );

    final allAfter = await ProfilesDao(db).getAll();
    final after = allAfter.firstWhere((p) => p.id == 'default');
    expect(after.emoji, '\u{1F33B}', reason: 'emoji must be updated');
    expect(after.createdAt, before.createdAt,
        reason: 'createdAt must not change on update');
    expect(after.sortOrder, before.sortOrder,
        reason: 'sortOrder must not change on update');
  });
}
