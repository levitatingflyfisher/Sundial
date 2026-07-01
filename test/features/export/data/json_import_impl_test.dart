// F10: the plaintext/JSON backup payload carries `annual_goal_hours`
// (json_export_impl.dart), but JsonImporter.parse never read it back, so
// callers had no way to restore the app's single most important setting.
// These tests pin that ImportPayload now exposes the goal.

import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/export/data/json_import_impl.dart';

void main() {
  group('JsonImporter — annual goal', () {
    test('parses annual_goal_hours when present', () {
      const json = '{"version": 3, "annual_goal_hours": 500, '
          '"sessions": [], "profiles": [], "badges": []}';

      final payload = JsonImporter().parse(json);

      expect(payload.annualGoalHours, 500);
    });

    test('annualGoalHours is null when the field is absent (older backup)',
        () {
      const json =
          '{"version": 1, "sessions": [], "profiles": [], "badges": []}';

      final payload = JsonImporter().parse(json);

      expect(payload.annualGoalHours, isNull);
    });

    test('annualGoalHours is null when the field has the wrong type', () {
      const json = '{"version": 3, "annual_goal_hours": "not a number", '
          '"sessions": [], "profiles": [], "badges": []}';

      final payload = JsonImporter().parse(json);

      expect(payload.annualGoalHours, isNull);
    });
  });
}
