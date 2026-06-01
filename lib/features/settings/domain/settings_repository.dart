import 'package:sundial/features/settings/domain/user_prefs.dart';

abstract interface class SettingsRepository {
  Future<UserPrefs> getUserPrefs();
  Stream<AppMode> watchAppMode();
  Stream<UserPrefs> watchUserPrefs();
  Future<void> setAppMode(AppMode mode);
  Future<void> setAnnualGoalHours(int hours);
  Future<void> setMonthlyGoalHours(int? hours);
  Future<void> setFlowTimerStyle(FlowTimerStyle style);
  Future<void> setAutoStop({required bool enabled, int thresholdHours = 2});
  Future<void> setDarkMode(bool dark);
  Future<void> setTimeFormat(TimeFormat format);
  Future<void> setWeekStart(WeekStart start);
}
