import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/profiles/presentation/profiles_screen.dart';

/// Removing a person is a deliberate tap (a trash button beside their name),
/// so per the fleet ruling it does not ask: it removes at once and offers an
/// Undo that stays until the person acts or leaves the screen.
void main() {
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((_) => db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(home: ProfilesScreen()),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await db.close();
  }

  testWidgets('trash removes at once, no dialog, and Undo brings them back',
      (tester) async {
    await tester.runAsync(() => db.into(db.profiles).insert(
        ProfilesCompanion.insert(
            id: 'dad', name: 'Dad', colorValue: 0xFF00FF00, createdAt: 1)));
    await pumpScreen(tester);
    expect(find.text('Dad'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove Dad'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing,
        reason: 'a deliberate delete does not ask');
    expect(find.text('Dad'), findsNothing);
    expect(find.text('Undo'), findsOneWidget);

    // No timer: the offer is still there much later.
    await tester.pump(const Duration(minutes: 10));
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Dad'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);

    await drain(tester);
  });
}
