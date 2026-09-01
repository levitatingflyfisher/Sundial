import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openhearth_design/openhearth_design.dart';
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

  // The theme used to be a bool stored under 'theme' as 'dark' / 'light',
  // defaulting to light, so following the phone was unreachable. It is now a
  // three-way preference (default: follow the phone) under a new key. Ruling:
  // a stored dark stays dark; a stored light becomes follow-phone, because
  // light was the default and most lights mean "never chosen".
  group('theme preference', () {
    Future<void> legacy(String value) => db
        .into(db.userPrefs)
        .insert(UserPrefsCompanion.insert(key: 'theme', value: value));

    test('defaults to follow the phone', () async {
      expect((await repo.getUserPrefs()).themeMode,
          OhThemeModePreference.system);
    });

    test('legacy dark migrates to dark', () async {
      await legacy('dark');
      expect(
          (await repo.getUserPrefs()).themeMode, OhThemeModePreference.dark);
    });

    test('legacy light migrates to follow the phone', () async {
      await legacy('light');
      expect((await repo.getUserPrefs()).themeMode,
          OhThemeModePreference.system);
    });

    test('an explicit choice wins over the legacy value, light included',
        () async {
      await legacy('dark');
      await repo.setThemeMode(OhThemeModePreference.light);
      expect(
          (await repo.getUserPrefs()).themeMode, OhThemeModePreference.light);
      await repo.setThemeMode(OhThemeModePreference.system);
      expect((await repo.getUserPrefs()).themeMode,
          OhThemeModePreference.system);
    });

    test('watchUserPrefs streams the change', () async {
      await repo.setThemeMode(OhThemeModePreference.dark);
      expect((await repo.watchUserPrefs().first).themeMode,
          OhThemeModePreference.dark);
    });
  });
}
