import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/storage/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  group('AppDatabase', () {
    test('opens without error', () async {
      await db.customSelect('SELECT 1').get();
    });

    test('sessions table exists and is empty', () async {
      final rows = await db.select(db.sessions).get();
      expect(rows, isEmpty);
    });

    test('badges table is seeded with milestones', () async {
      final rows = await db.select(db.badges).get();
      expect(rows, isNotEmpty);
      expect(rows.map((b) => b.thresholdHours), containsAll([10, 50, 100, 1000]));
      expect(rows.every((b) => b.earnedAt == null), isTrue);
    });

    test('user_prefs table exists and is empty', () async {
      final rows = await db.select(db.userPrefs).get();
      expect(rows, isEmpty);
    });
  });
}
