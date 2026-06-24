enum AppMode { flow, rich }

enum FlowTimerStyle { arc, gnomon, dualRing }

enum TimeFormat { h12, h24 }

enum WeekStart { sunday, monday }

class UserPrefs {
  const UserPrefs({
    this.annualGoalHours = 1000,
    this.monthlyGoalHours,
    this.appMode = AppMode.flow,
    this.flowTimerStyle = FlowTimerStyle.gnomon,
    this.autoStopEnabled = false,
    this.autoStopThresholdHours = 2,
    this.isDarkMode = false,
    this.timeFormat = TimeFormat.h12,
    this.weekStart = WeekStart.sunday,
  });

  final int annualGoalHours;
  final int? monthlyGoalHours;
  final AppMode appMode;
  final FlowTimerStyle flowTimerStyle;
  final bool autoStopEnabled;
  final int autoStopThresholdHours;
  final bool isDarkMode;
  final TimeFormat timeFormat;
  final WeekStart weekStart;
}
