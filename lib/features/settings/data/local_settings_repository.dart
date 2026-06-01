import 'package:drift/drift.dart';
import 'package:sundial/core/storage/app_database.dart' hide UserPrefs;
import 'package:sundial/features/settings/domain/settings_repository.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._db);
  final AppDatabase _db;

  static const _kAnnualGoal = 'annual_goal_hours';
  static const _kMonthlyGoal = 'monthly_goal_hours';
  static const _kAppMode = 'app_mode';
  static const _kTimerStyle = 'flow_timer_style';
  static const _kAutoStopEnabled = 'auto_stop_enabled';
  static const _kAutoStopHours = 'auto_stop_threshold_hours';
  static const _kDarkMode = 'theme';
  static const _kTimeFormat = 'time_format';
  static const _kWeekStart = 'week_start';

  Future<void> _set(String key, String value) => _db
      .into(_db.userPrefs)
      .insertOnConflictUpdate(UserPrefsCompanion.insert(key: key, value: value));

  Stream<String?> _watch(String key) =>
      (_db.select(_db.userPrefs)..where((t) => t.key.equals(key)))
          .watchSingleOrNull()
          .map((r) => r?.value);

  @override
  Future<UserPrefs> getUserPrefs() async {
    final rows = await _db.select(_db.userPrefs).get();
    final map = {for (final r in rows) r.key: r.value};
    return _fromMap(map);
  }

  @override
  Stream<UserPrefs> watchUserPrefs() =>
      _db.select(_db.userPrefs).watch().map((rows) {
        final map = {for (final r in rows) r.key: r.value};
        return _fromMap(map);
      });

  @override
  Stream<AppMode> watchAppMode() =>
      _watch(_kAppMode).map((v) => _parseMode(v));

  @override
  Future<void> setAppMode(AppMode mode) =>
      _set(_kAppMode, mode == AppMode.flow ? 'flow' : 'rich');

  @override
  Future<void> setAnnualGoalHours(int hours) =>
      _set(_kAnnualGoal, hours.toString());

  @override
  Future<void> setMonthlyGoalHours(int? hours) async {
    if (hours == null) {
      await (_db.delete(_db.userPrefs)
            ..where((t) => t.key.equals(_kMonthlyGoal)))
          .go();
    } else {
      await _set(_kMonthlyGoal, hours.toString());
    }
  }

  @override
  Future<void> setFlowTimerStyle(FlowTimerStyle style) =>
      _set(_kTimerStyle, style.name);

  @override
  Future<void> setAutoStop({required bool enabled, int thresholdHours = 2}) async {
    await _set(_kAutoStopEnabled, enabled ? 'true' : 'false');
    await _set(_kAutoStopHours, thresholdHours.toString());
  }

  @override
  Future<void> setDarkMode(bool dark) =>
      _set(_kDarkMode, dark ? 'dark' : 'light');

  @override
  Future<void> setTimeFormat(TimeFormat format) =>
      _set(_kTimeFormat, format == TimeFormat.h12 ? '12h' : '24h');

  @override
  Future<void> setWeekStart(WeekStart start) =>
      _set(_kWeekStart, start == WeekStart.monday ? 'monday' : 'sunday');

  UserPrefs _fromMap(Map<String, String> map) => UserPrefs(
    annualGoalHours: int.tryParse(map[_kAnnualGoal] ?? '') ?? 1000,
    monthlyGoalHours: int.tryParse(map[_kMonthlyGoal] ?? ''),
    appMode: _parseMode(map[_kAppMode]),
    flowTimerStyle: _parseStyle(map[_kTimerStyle]),
    autoStopEnabled: map[_kAutoStopEnabled] == 'true',
    autoStopThresholdHours: int.tryParse(map[_kAutoStopHours] ?? '') ?? 2,
    isDarkMode: map[_kDarkMode] == 'dark',
    timeFormat: map[_kTimeFormat] == '24h' ? TimeFormat.h24 : TimeFormat.h12,
    weekStart: map[_kWeekStart] == 'monday' ? WeekStart.monday : WeekStart.sunday,
  );

  AppMode _parseMode(String? v) => v == 'rich' ? AppMode.rich : AppMode.flow;

  FlowTimerStyle _parseStyle(String? v) => switch (v) {
    'arc' => FlowTimerStyle.arc,
    'dual_ring' => FlowTimerStyle.dualRing,
    _ => FlowTimerStyle.gnomon,
  };
}
