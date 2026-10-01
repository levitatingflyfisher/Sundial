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

/// Ruling Q-D1, the rest of the accepted recommendation: with Flow the
/// default, History, Stats and Settings must be reachable from Flow without
/// switching mode (audit Contested row: "Flow has no route to History,
/// Stats or Settings").
void main() {
  for (final (word, page) in [
    ('History', 'history page'),
    ('Stats', 'stats page'),
    ('Settings', 'settings page'),
  ]) {
    testWidgets('Flow opens $word and comes back', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      Widget stub(String text) => Center(child: Text(text));
      final router = GoRouter(initialLocation: '/timer', routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(path: '/timer', builder: (_, __) => stub('timer page')),
            GoRoute(path: '/history', builder: (_, __) => stub('history page')),
            GoRoute(path: '/stats', builder: (_, __) => stub('stats page')),
            GoRoute(
                path: '/settings', builder: (_, __) => stub('settings page')),
          ],
        ),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWith((_) => db),
          appModeProvider.overrideWith((_) => Stream.value(AppMode.flow)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(FlowScreen), findsOneWidget);

      await tester.ensureVisible(find.text(word));
      await tester.tap(find.text(word));
      await tester.pumpAndSettle();
      expect(find.text(page), findsOneWidget,
          reason: 'still in Flow mode, the page opens');

      await tester.tap(find.byTooltip('Back to the timer'));
      await tester.pumpAndSettle();
      expect(find.byType(FlowScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
      await db.close();
    });
  }
}
