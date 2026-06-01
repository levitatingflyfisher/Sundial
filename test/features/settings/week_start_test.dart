import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/settings/data/local_settings_repository.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';

void main() {
  group('WeekStart persistence', () {
    test('defaults to sunday', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = LocalSettingsRepository(db);

      final prefs = await repo.getUserPrefs();
      expect(prefs.weekStart, WeekStart.sunday);
    });

    test('round-trips monday', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = LocalSettingsRepository(db);

      await repo.setWeekStart(WeekStart.monday);
      final prefs = await repo.getUserPrefs();
      expect(prefs.weekStart, WeekStart.monday);
    });

    test('round-trips sunday after monday', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = LocalSettingsRepository(db);

      await repo.setWeekStart(WeekStart.monday);
      await repo.setWeekStart(WeekStart.sunday);
      final prefs = await repo.getUserPrefs();
      expect(prefs.weekStart, WeekStart.sunday);
    });
  });
}
