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
}
