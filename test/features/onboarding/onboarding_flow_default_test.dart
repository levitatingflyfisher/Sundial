import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/onboarding/presentation/onboarding_screen.dart';

/// Audit finding 4 / ruling Q-D1: onboarding forced a Flow-or-Rich fork on
/// its second page before the household had timed a minute outside. Flow is
/// the default now: Get started opens straight into the timer, and Rich is
/// offered later, in context, from Flow itself.
void main() {
  testWidgets('Get started opens Flow, with no mode fork', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    final router = GoRouter(initialLocation: '/onboarding', routes: [
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(
          path: '/timer',
          builder: (_, __) => const Scaffold(body: Text('timer here'))),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((_) => db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.text('Get started'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('How do you want to start'), findsNothing);
    expect(find.text('timer here'), findsOneWidget);
    final rows = await tester.runAsync(() => db.select(db.userPrefs).get());
    expect({for (final r in rows!) r.key: r.value}['app_mode'], 'flow',
        reason: 'Flow is stored, so the router lets the household out');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await db.close();
  });
}
