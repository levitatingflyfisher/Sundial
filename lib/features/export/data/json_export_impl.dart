import 'dart:convert';
import 'package:sundial/core/storage/app_database.dart';

class JsonExporter {
  String buildJson(
    List<Session> sessions, {
    required int annualGoalHours,
    List<Profile> profiles = const [],
    List<Badge> badges = const [],
  }) {
    return jsonEncode({
      'version': 3,
      'exported': DateTime.now().toIso8601String(),
      'annual_goal_hours': annualGoalHours,
      'profiles': profiles
          .map((p) => {
                'id': p.id,
                'name': p.name,
                if (p.emoji != null) 'emoji': p.emoji,
                'color_value': p.colorValue,
                'sort_order': p.sortOrder,
                'created_at': p.createdAt,
              })
          .toList(),
      'sessions': sessions
          .map((s) => {
                'id': s.id,
                'start_time': s.startTime,
                'end_time': s.endTime,
                'duration_secs': s.durationSecs,
                'date_day': s.dateDay,
                if (s.profileId != null) 'profile_id': s.profileId,
                if (s.notes != null) 'notes': s.notes,
                'created_at': s.createdAt,
                'updated_at': s.updatedAt,
              })
          .toList(),
      // Only earned badges are written. Seed rows and thresholds are derived
      // from the install's migration, so a restore only needs to know which
      // ids were earned and when.
      'badges': badges
          .where((b) => b.earnedAt != null)
          .map((b) => {
                'id': b.id,
                'earned_at': b.earnedAt,
              })
          .toList(),
    });
  }
}
