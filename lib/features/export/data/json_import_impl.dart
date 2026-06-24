import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:sundial/core/storage/app_database.dart';

/// Parsed payload from a Sundial JSON backup.
class ImportPayload {
  const ImportPayload({
    required this.sessions,
    required this.profiles,
    required this.earnedBadges,
  });
  final List<Session> sessions;
  final List<ProfilesCompanion> profiles;

  /// Earned badge ids → earned-at millis. Only populated for v3+ backups.
  final Map<String, int> earnedBadges;
}

class JsonImporter {
  /// Parses a Sundial JSON backup (v1, v2, or v3).
  /// Throws [FormatException] if the content is not valid Sundial JSON.
  ImportPayload parse(String jsonContent) {
    final data = jsonDecode(jsonContent) as Map<String, dynamic>;
    final version = (data['version'] as int?) ?? 1;
    final now = DateTime.now().millisecondsSinceEpoch;

    final profilesList = (data['profiles'] as List<dynamic>?) ?? const [];
    final profiles = profilesList.map<ProfilesCompanion>((p) {
      final m = p as Map<String, dynamic>;
      return ProfilesCompanion(
        id: Value(m['id'] as String),
        name: Value(m['name'] as String),
        emoji: Value(m['emoji'] as String?),
        colorValue: Value(m['color_value'] as int),
        sortOrder: Value((m['sort_order'] as int?) ?? 0),
        createdAt: Value((m['created_at'] as int?) ?? now),
      );
    }).toList();

    final sessionsList = (data['sessions'] as List<dynamic>?) ?? const [];
    final sessions = sessionsList.map<Session>((s) {
      final m = s as Map<String, dynamic>;
      return Session(
        id: m['id'] as String,
        startTime: m['start_time'] as int,
        endTime: m['end_time'] as int,
        durationSecs: m['duration_secs'] as int,
        dateDay: m['date_day'] as String,
        profileId: version >= 2 ? m['profile_id'] as String? : null,
        notes: m['notes'] as String?,
        locationLabel: null,
        lat: null,
        lng: null,
        createdAt: m['created_at'] as int? ?? now,
        updatedAt: m['updated_at'] as int? ?? now,
      );
    }).toList();

    final badgesList = (data['badges'] as List<dynamic>?) ?? const [];
    final earnedBadges = <String, int>{
      for (final b in badgesList)
        (b as Map<String, dynamic>)['id'] as String: b['earned_at'] as int,
    };

    return ImportPayload(
      sessions: sessions,
      profiles: profiles,
      earnedBadges: earnedBadges,
    );
  }
}
