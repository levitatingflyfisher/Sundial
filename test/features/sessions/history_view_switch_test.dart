import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/sessions/presentation/history_screen.dart';

/// Audit finding 10: History's view switch was one icon whose name lived
/// only in a tooltip (no hover on a phone), and every switch threw the
/// browsed month away. It is now two worded segments, Calendar and List,
/// and the month survives a round trip.
void main() {
  late SharedPreferences prefs;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('Calendar | List are words, and the month is kept',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((_) => db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(home: HistoryScreen()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('List'), findsOneWidget);

    final now = DateTime.now();
    final fmt = DateFormat('MMMM yyyy');
    final earlier = DateTime(now.year, now.month - 2);
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pump();
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pump();
    expect(find.text(fmt.format(earlier)), findsOneWidget);

    await tester.tap(find.text('List'));
    await tester.pump();
    await tester.tap(find.text('Calendar'));
    await tester.pump();
    expect(find.text(fmt.format(earlier)), findsOneWidget,
        reason: 'switching views must not throw the month away');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  testWidgets('the switch fits at 320dp x 1.3', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((_) => db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
              size: Size(320, 700), textScaler: TextScaler.linear(1.3)),
          child: HistoryScreen(),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.text('Calendar'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  // Q-D3: search lived in the List view only. The field now sits above both
  // views, and typing while the calendar shows switches to the List with
  // the matches (a calendar has no meaning for a text search).
  testWidgets('typing a search on the calendar switches to the List',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final now = DateTime.now();
    await tester.runAsync(() async {
      for (final (id, note) in [('a', 'Creek walk'), ('b', 'Park picnic')]) {
        final start = DateTime(now.year, now.month, 1, 9);
        await db.into(db.sessions).insert(SessionsCompanion.insert(
              id: id,
              startTime: start.millisecondsSinceEpoch,
              endTime: start.millisecondsSinceEpoch + 3600000,
              durationSecs: 3600,
              notes: Value(note),
              dateDay: '${now.year}-${now.month.toString().padLeft(2, '0')}-01',
              createdAt: start.millisecondsSinceEpoch,
              updatedAt: start.millisecondsSinceEpoch,
            ));
      }
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((_) => db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(home: HistoryScreen()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    SegmentedButton<dynamic> seg() => tester.widget(find.byWidgetPredicate(
        (w) => w is SegmentedButton));
    final calendarSelected = seg().selected.single;

    expect(find.byType(TextField), findsOneWidget,
        reason: 'the search field is there on the calendar too');
    await tester.enterText(find.byType(TextField), 'creek');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(seg().selected.single, isNot(calendarSelected),
        reason: 'a query switches to the List');
    expect(find.textContaining('Creek walk'), findsOneWidget);
    expect(find.textContaining('Park picnic'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
