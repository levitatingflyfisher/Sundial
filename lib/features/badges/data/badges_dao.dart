// lib/features/badges/data/badges_dao.dart
import 'package:drift/drift.dart';
import 'package:sundial/core/storage/app_database.dart';

part 'badges_dao.g.dart';

@DriftAccessor(tables: [Badges])
class BadgesDao extends DatabaseAccessor<AppDatabase> with _$BadgesDaoMixin {
  BadgesDao(super.db);

  Stream<List<Badge>> watchAll() => select(badges).watch();

  Future<List<Badge>> getAll() => select(badges).get();

  Future<void> markEarned(String id, int earnedAtMs) =>
      (update(badges)..where((t) => t.id.equals(id))).write(
        BadgesCompanion(earnedAt: Value(earnedAtMs)),
      );

  Future<void> markRevoked(String id) =>
      (update(badges)..where((t) => t.id.equals(id))).write(
        const BadgesCompanion(earnedAt: Value(null)),
      );
}
