import 'package:intl/intl.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/shared/extensions/duration_ext.dart';

class PlaintextExporter {
  static final _timeFmt = DateFormat('HH:mm');

  String formatSession(Session s) {
    final start = DateTime.fromMillisecondsSinceEpoch(s.startTime);
    final end = DateTime.fromMillisecondsSinceEpoch(s.endTime);
    final dur = Duration(seconds: s.durationSecs).toHoursLabel();
    final timeRange = '${_timeFmt.format(start)}–${_timeFmt.format(end)}';
    final notesPart = s.notes != null ? '  "${s.notes}"' : '';
    return '${s.dateDay}  $timeRange  ($dur)$notesPart';
  }

  String buildFile(List<Session> sessions, {required int annualGoalHours}) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final header = '# Sundial Backup\n# Exported: $today\n# Annual goal: ${annualGoalHours}h\n\n';
    final lines = sessions.map(formatSession).join('\n');
    return '$header$lines\n';
  }
}
