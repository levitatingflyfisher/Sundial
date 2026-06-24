import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/settings/data/local_settings_repository.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';

void main() {
  late AppDatabase db;
  late LocalSettingsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LocalSettingsRepository(db);
  });

  tearDown(() => db.close());

  group('LocalSettingsRepository', () {
    test('annualGoalHours defaults to 1000', () async {
      final prefs = await repo.getUserPrefs();
      expect(prefs.annualGoalHours, 1000);
    });

    test('appMode defaults to flow', () async {
      final prefs = await repo.getUserPrefs();
      expect(prefs.appMode, AppMode.flow);
    });

    test('flowTimerStyle defaults to gnomon', () async {
      final prefs = await repo.getUserPrefs();
      expect(prefs.flowTimerStyle, FlowTimerStyle.gnomon);
    });

    test('setAnnualGoalHours persists value', () async {
      await repo.setAnnualGoalHours(500);
      final prefs = await repo.getUserPrefs();
      expect(prefs.annualGoalHours, 500);
    });

    test('setAppMode persists value', () async {
      await repo.setAppMode(AppMode.rich);
      final prefs = await repo.getUserPrefs();
      expect(prefs.appMode, AppMode.rich);
    });

    test('watchAppMode streams changes', () async {
      expect(await repo.watchAppMode().first, AppMode.flow);
      await repo.setAppMode(AppMode.rich);
      expect(await repo.watchAppMode().first, AppMode.rich);
    });
  });
}
