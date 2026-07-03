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
    final sessions = sessionsList
        .map((s) => _parseSession(s, now, version))
        .whereType<Session>()
        .toList();

    final badgesList = (data['badges'] as List<dynamic>?) ?? const [];
    final earnedBadges = <String, int>{
      for (final b in badgesList)
        if (b is Map<String, dynamic> &&
            b['id'] is String &&
            b['earned_at'] is int)
          b['id'] as String: b['earned_at'] as int,
    };

    return ImportPayload(
      sessions: sessions,
      profiles: profiles,
      earnedBadges: earnedBadges,
    );
  }

  /// Parses one exported session, returning null (skip) when a required field
  /// is missing/foreign-typed or the capture invariants are violated — so one
  /// bad or foreign row can't abort the entire import with a raw type error.
  Session? _parseSession(dynamic raw, int now, int version) {
    if (raw is! Map<String, dynamic>) return null;
    final id = raw['id'];
    final start = raw['start_time'];
    final end = raw['end_time'];
    final dur = raw['duration_secs'];
    final dateDay = raw['date_day'];
    if (id is! String ||
        start is! int ||
        end is! int ||
        dur is! int ||
        dateDay is! String ||
        start > end) {
      return null;
    }
    // Clamp to the capture-path invariant [0, 86400] (a day) so an out-of-range
    // imported value can't poison stats.
    final clampedDur = dur < 0 ? 0 : (dur > 86400 ? 86400 : dur);
    return Session(
      id: id,
      startTime: start,
      endTime: end,
      durationSecs: clampedDur,
      dateDay: dateDay,
      profileId: version >= 2 && raw['profile_id'] is String
          ? raw['profile_id'] as String
          : null,
      notes: raw['notes'] is String ? raw['notes'] as String : null,
      locationLabel: null,
      lat: null,
      lng: null,
      createdAt: raw['created_at'] is int ? raw['created_at'] as int : now,
      updatedAt: raw['updated_at'] is int ? raw['updated_at'] as int : now,
    );
  }
}
