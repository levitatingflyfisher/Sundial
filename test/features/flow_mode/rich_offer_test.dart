import 'package:drift/drift.dart' show InsertMode, Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/flow_mode/presentation/flow_screen.dart';

/// Ruling Q-D1 (gamers-brain's middle path): Flow is the default, and Rich
/// is offered later in context: once the household has a session saved,
/// Flow says once what Rich adds. Not now puts the offer away for good; the
/// mode pill stays for anyone who wants to switch later.
void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

  Future<void> pump(WidgetTester tester, {required bool withSession}) async {
    if (withSession) {
      final now = DateTime.now();
      await tester.runAsync(() => db.into(db.sessions).insert(
            SessionsCompanion.insert(
              id: 's',
              startTime: now.millisecondsSinceEpoch,
              endTime: now.millisecondsSinceEpoch + 1800000,
              durationSecs: 1800,
              dateDay: '${now.year}-${now.month.toString().padLeft(2, '0')}-'
                  '${now.day.toString().padLeft(2, '0')}',
              profileId: const Value(null),
              createdAt: 0,
              updatedAt: 0,
            ),
            mode: InsertMode.insertOrReplace,
          ));
    }
    await tester.binding.setSurfaceSize(const Size(600, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((_) => db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(home: FlowScreen()),
    ));
    await tester.pumpAndSettle();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
  });

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await db.close();
  }

  testWidgets('no offer before the first session', (tester) async {
    await pump(tester, withSession: false);
    expect(find.text('Show me Rich'), findsNothing);
    await drain(tester);
  });

  testWidgets('after a session, Flow offers Rich once; Not now is for good',
      (tester) async {
    await pump(tester, withSession: true);
    expect(find.textContaining('History, Stats and badges'), findsOneWidget);
    expect(find.text('Show me Rich'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Show me Rich'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await pump(tester, withSession: false);
    expect(find.text('Show me Rich'), findsNothing,
        reason: 'the offer stays put away');
    await drain(tester);
  });

  testWidgets('Show me Rich switches the mode', (tester) async {
    await pump(tester, withSession: true);
    await tester.runAsync(() async {
      await tester.tap(find.text('Show me Rich'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    final rows = await tester.runAsync(() => db.select(db.userPrefs).get());
    expect({for (final r in rows!) r.key: r.value}['app_mode'], 'rich');
    await drain(tester);
  });
}
