// lib/core/storage/app_database.dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ─── Tables ───────────────────────────────────────────────────────────────────

class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get emoji => text().nullable()();
  IntColumn get colorValue => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class Sessions extends Table {
  TextColumn get id => text()();
  IntColumn get startTime => integer()();
  IntColumn get endTime => integer()();
  IntColumn get durationSecs => integer()();
  TextColumn get notes => text().nullable()();
  TextColumn get dateDay => text()();
  TextColumn get profileId => text().nullable().references(Profiles, #id)();
  // Phase 3 columns — nullable, unused in Phase 1
  TextColumn get locationLabel => text().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class Badges extends Table {
  TextColumn get id => text()();
  IntColumn get thresholdHours => integer()();
  IntColumn get earnedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class UserPrefs extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Profiles, Sessions, Badges, UserPrefs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ??
            driftDatabase(
              name: 'sundial',
              // Web needs to know where the sqlite3 WASM engine + drift worker
              // live (both shipped in web/); without this drift_flutter throws
              // "the `web` parameter needs to be set" at startup.
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedBadges();
      await _seedDefaultProfile();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Add the 25h, 75h, 250h, 750h milestone badges added in v2.
        const newMilestones = [25, 75, 250, 750];
        for (final h in newMilestones) {
          await into(badges).insertOnConflictUpdate(
            BadgesCompanion.insert(id: 'badge_${h}h', thresholdHours: h),
          );
        }
      }
      if (from < 3) {
        // Add Profiles table and sessions.profileId column.
        await m.createTable(profiles);
        await m.addColumn(sessions, sessions.profileId);
        await _seedDefaultProfile();
      }
    },
  );

  Future<void> _seedBadges() async {
    const milestones = [10, 25, 50, 75, 100, 200, 250, 300, 400, 500, 600, 700, 750, 800, 900, 1000];
    for (final h in milestones) {
      await into(badges).insert(
        BadgesCompanion.insert(id: 'badge_${h}h', thresholdHours: h),
      );
    }
  }

  Future<void> _seedDefaultProfile() async {
    await into(profiles).insertOnConflictUpdate(
      ProfilesCompanion.insert(
        id: 'default',
        name: 'Me',
        colorValue: 0xFF5E9478, // sage green
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
