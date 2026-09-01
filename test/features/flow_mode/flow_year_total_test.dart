import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/flow_mode/presentation/flow_screen.dart';
import 'package:sundial/features/flow_mode/presentation/sundial_face.dart';

/// visual-02: FlowScreen never passed the year total to SundialFace, which
/// defaulted it to 0, so the Dual Ring's outer ring never filled and its
/// caption read "0h / 1000h" forever. The face now requires the total (no
/// default, so a call site that forgets it does not compile) and Flow feeds
/// it the same stream as its year line.
void main() {
  testWidgets('Flow passes this year\'s total to the face', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    final now = DateTime.now();
    final day = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    await db.into(db.sessions).insert(SessionsCompanion.insert(
          id: 's',
          startTime: now.millisecondsSinceEpoch,
          endTime: now.millisecondsSinceEpoch + 1800000,
          durationSecs: 1800,
          dateDay: day,
          profileId: const Value(null),
          createdAt: 0,
          updatedAt: 0,
        ));

    await tester.binding.setSurfaceSize(const Size(600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((_) => db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(home: FlowScreen()),
    ));
    await tester.pumpAndSettle();

    expect(tester.widget<SundialFace>(find.byType(SundialFace)).yearTotal,
        const Duration(minutes: 30));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await db.close();
  });
}
