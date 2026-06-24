// test/features/widget_launch_override_test.dart
//
// Item 6 of the 2026-04-09 multi-profile completion plan.
// When Android's home widget is tapped, we want the app to land in FlowScreen
// (the "relaxed simple view") regardless of the user's durable AppMode
// preference. The override is transient — it clears on AppLifecycleState.paused
// so the next launcher-icon launch restores the Rich shell.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/router/app_shell.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/flow_mode/presentation/flow_screen.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';
import 'package:sundial/shared/widgets/mode_pill.dart';

/// Minimal wrapper that stubs the GoRouterState the _RichShell's inner
/// NavigationBar reads. We install a trivial GoRouter with a single route so
/// GoRouterState.of(context) is valid inside the shell.
Widget _harness({
  required AppDatabase db,
  required SharedPreferences prefs,
  required bool widgetLaunch,
  required AppMode mode,
}) {
  final router = GoRouter(
    initialLocation: '/timer',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/timer',
            builder: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWith((_) => db),
      widgetLaunchOverrideProvider.overrideWith((_) => widgetLaunch),
      appModeProvider.overrideWith((_) => Stream.value(mode)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _tearDown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  group('widget launch forces Flow mode', () {
    testWidgets(
        'AppShell renders FlowScreen when override=true even if AppMode is rich',
        (tester) async {
      // FlowScreen renders a large AspectRatio sundial face; a bigger surface
      // keeps the layout from overflowing in the headless test window.
      await tester.binding.setSurfaceSize(const Size(600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());

      await tester.pumpWidget(_harness(
        db: db,
        prefs: prefs,
        widgetLaunch: true,
        mode: AppMode.rich,
      ));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(FlowScreen), findsOneWidget,
          reason: 'widget launch must force Flow mode');
      expect(find.byType(NavigationBar), findsNothing,
          reason: 'Rich shell NavigationBar must not render');

      await _tearDown(tester);
    });

    testWidgets(
        'AppShell renders rich shell when override=false and AppMode=rich',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());

      await tester.pumpWidget(_harness(
        db: db,
        prefs: prefs,
        widgetLaunch: false,
        mode: AppMode.rich,
      ));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(NavigationBar), findsOneWidget,
          reason: 'normal launch must show Rich shell');
      expect(find.byType(FlowScreen), findsNothing);

      await _tearDown(tester);
    });

    testWidgets(
        'override clears on app lifecycle pause',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());

      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((_) => db),
      ]);
      addTearDown(container.dispose);

      // Activate the lifecycle observer (side-effect on first read).
      container.read(widgetLaunchLifecycleObserverProvider);

      // Arrange: override set to true (simulating a fresh widget tap).
      container.read(widgetLaunchOverrideProvider.notifier).state = true;
      expect(container.read(widgetLaunchOverrideProvider), isTrue);

      // Act: emit AppLifecycleState.paused through the binding so the global
      // observer clears the override.
      WidgetsBinding.instance
          .handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // Assert: override has been cleared.
      expect(container.read(widgetLaunchOverrideProvider), isFalse,
          reason: 'paused lifecycle must clear widget launch override');
    });

    testWidgets('ModePill Rich tap clears widgetLaunchOverrideProvider',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());

      final router = GoRouter(
        initialLocation: '/timer',
        routes: [
          GoRoute(
            path: '/timer',
            builder: (_, __) => const Scaffold(body: ModePill()),
          ),
        ],
      );

      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((_) => db),
        widgetLaunchOverrideProvider.overrideWith((_) => true),
        appModeProvider.overrideWith((_) => Stream.value(AppMode.flow)),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(container.read(widgetLaunchOverrideProvider), isTrue,
          reason: 'precondition: override starts true');

      await tester.tap(find.text('Rich'));
      await tester.pump();

      expect(container.read(widgetLaunchOverrideProvider), isFalse,
          reason: 'Rich tap must clear widget launch override');

      await _tearDown(tester);
    });
  });
}
