import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/router/app_shell.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';
import 'package:sundial/features/settings/presentation/settings_screen.dart';

/// Theme is light, dark or follow the phone, one control in the app bar of
/// every primary screen (Rich tabs and Flow), at most two taps to any mode.
/// There is exactly one home for it: Settings no longer carries a second
/// "Dark mode" switch.
void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
  });

  Widget app(AppMode mode, {Widget tab = const SizedBox.expand()}) =>
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWith((_) => db),
          appModeProvider.overrideWith((_) => Stream.value(mode)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/timer',
            routes: [
              ShellRoute(
                builder: (context, state, child) => AppShell(child: child),
                routes: [GoRoute(path: '/timer', builder: (_, __) => tab)],
              ),
            ],
          ),
        ),
      );

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await db.close();
  }

  for (final mode in AppMode.values) {
    testWidgets('${mode.name}: app bar toggle, two taps to Dark, persisted',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app(mode));
      await tester.pumpAndSettle();

      final toggle = find.descendant(
          of: find.byType(AppBar), matching: find.byType(OhThemeToggle));
      expect(toggle, findsOneWidget);
      expect(find.text('Auto'), findsOneWidget,
          reason: 'default is follow the phone, with a visible word');

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      final stored = await tester
          .runAsync(() => db.select(db.userPrefs).get())
          .then((rows) => {for (final r in rows!) r.key: r.value});
      expect(stored['theme_mode'], 'dark');
      expect(find.text('Dark'), findsOneWidget);
      await drain(tester);
    });
  }

  testWidgets('Settings has no second theme control', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(AppMode.rich, tab: const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Dark mode'), findsNothing);
    expect(find.byType(OhThemeToggle), findsOneWidget,
        reason: 'the app bar toggle is the one home');
    await drain(tester);
  });
}
