import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/export/data/plaintext_export_impl.dart';

Session _sess(String id, int durationSecs, String day, String? notes) =>
    Session(
      id: id,
      startTime: DateTime(2026, 3, 28, 9).millisecondsSinceEpoch,
      endTime: DateTime(2026, 3, 28, 9).millisecondsSinceEpoch + durationSecs * 1000,
      durationSecs: durationSecs,
      notes: notes,
      dateDay: day,
      locationLabel: null, lat: null, lng: null,
      createdAt: 0, updatedAt: 0,
    );

void main() {
  group('PlaintextExporter', () {
    final exporter = PlaintextExporter();

    test('formats session without notes', () {
      final line = exporter.formatSession(_sess('1', 9000, '2026-03-28', null));
      expect(line, contains('2026-03-28'));
      expect(line, contains('2h 30m'));
    });

    test('formats session with notes', () {
      final line = exporter.formatSession(
          _sess('1', 9000, '2026-03-28', 'park day with co-op'));
      expect(line, contains('"park day with co-op"'));
    });

    test('buildFile includes header and all sessions', () {
      final sessions = [
        _sess('1', 9000, '2026-03-28', 'park day'),
        _sess('2', 5400, '2026-03-27', null),
      ];
      final file = exporter.buildFile(sessions, annualGoalHours: 1000);
      expect(file, contains('# Sundial Backup'));
      expect(file, contains('Annual goal: 1000h'));
      expect(file, contains('2026-03-28'));
      expect(file, contains('2026-03-27'));
    });
  });
}
