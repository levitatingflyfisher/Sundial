import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/sessions/presentation/session_edit_sheet.dart';

/// Guards the session-edit save computation. The bug: editing an existing
/// session's date updated `dateDay` (used by calendar grouping + heatmap) but
/// left `startTime`/`endTime` on the old day (rendered by the card, re-read by
/// the editor, and exported) — so the session appeared on two different days.
void main() {
  Session existingOn(DateTime start, {int durationSecs = 3600}) => Session(
        id: 's1',
        startTime: start.millisecondsSinceEpoch,
        endTime: start.millisecondsSinceEpoch + durationSecs * 1000,
        durationSecs: durationSecs,
        notes: null,
        dateDay:
            '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
        locationLabel: null,
        lat: null,
        lng: null,
        createdAt: 0,
        updatedAt: 0,
      );

  test('editing an existing session date moves startTime/endTime to the new day',
      () {
    final existing = existingOn(DateTime(2026, 3, 28, 14, 30));
    final updated = SessionEditSheet.buildSessionForSave(
      existing: existing,
      sessionId: 's1',
      date: DateTime(2026, 3, 20),
      durationSecs: 3600,
      notes: '',
      nowMs: 999,
    );

    expect(updated.dateDay, '2026-03-20');
    final startDay = DateTime.fromMillisecondsSinceEpoch(updated.startTime);
    expect(startDay.year, 2026);
    expect(startDay.month, 3);
    expect(startDay.day, 20, reason: 'startTime must follow the edited date');
    expect(updated.endTime, updated.startTime + 3600 * 1000,
        reason: 'endTime must stay startTime + duration');
  });

  test('editing only duration keeps the original date, updated duration', () {
    final existing = existingOn(DateTime(2026, 3, 28), durationSecs: 3600);
    final updated = SessionEditSheet.buildSessionForSave(
      existing: existing,
      sessionId: 's1',
      date: DateTime(2026, 3, 28),
      durationSecs: 7200,
      notes: 'ran longer',
      nowMs: 999,
    );
    expect(updated.dateDay, '2026-03-28');
    expect(updated.durationSecs, 7200);
    expect(updated.endTime, updated.startTime + 7200 * 1000);
    expect(updated.notes, 'ran longer');
  });
}
