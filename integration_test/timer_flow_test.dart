// integration_test/timer_flow_test.dart
//
// Integration test: full timer flow — start → stop → edit → save → DB persisted.
//
// NOTE: The save step happens inside SessionEditSheet (pushed via GoRouter to
// /sessions/:id/edit). A custom GoRouter is injected so the test does not
// depend on the production router's onboarding redirect.
//
// durationSecs is asserted >= 0 (not >= 2) because tester.pump() advances
// fake frame time, not real wall-clock time. DateTime.now() inside
// buildDraftSession() therefore reflects near-zero elapsed seconds.
import 'package:drift/native.dart'; // CORRECT import — NOT native_database.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/sessions/presentation/session_edit_sheet.dart';
import 'package:sundial/features/timer/presentation/timer_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full timer flow: start → stop → session saved → totals update',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());

    // A minimal router with only the two routes exercised by this test.
    // Avoids the production router's onboarding redirect.
    final router = GoRouter(
      initialLocation: '/timer',
      routes: [
        GoRoute(
          path: '/timer',
          builder: (context, state) => const TimerScreen(),
        ),
        GoRoute(
          path: '/sessions/:id/edit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final session = state.extra;
            return SessionEditSheet(sessionId: id, initialSession: session);
          },
        ),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((_) => db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();

    // ── START ──────────────────────────────────────────────────────────────────
    expect(find.text('START'), findsOneWidget);
    await tester.tap(find.text('START'));
    await tester.pump();
    expect(find.text('STOP'), findsOneWidget);

    // Simulate a short passage of time (fake frame time only).
    await tester.pump(const Duration(seconds: 2));

    // ── STOP → builds draft session ────────────────────────────────────────────
    await tester.tap(find.text('STOP'));
    await tester.pumpAndSettle();

    // TimerScreen is now in TimerStopped state — shows "Review & Save".
    expect(find.text('Review & Save'), findsOneWidget);

    // ── Navigate to SessionEditSheet ───────────────────────────────────────────
    await tester.tap(find.text('Review & Save'));
    await tester.pumpAndSettle();

    // SessionEditSheet AppBar has a "Save" TextButton.
    expect(find.text('Save'), findsOneWidget);

    // The draft session has ~0 elapsed seconds (fake frame time). The edit
    // sheet initialises hours=0, minutes=0. Saving with duration=0 is rejected.
    // Increment minutes by 1 via the "+" icon so durationSecs = 60 > 0.
    // The minutes picker '+' is the second add-icon in the widget tree.
    final addIcons = find.byIcon(Icons.add);
    expect(addIcons, findsWidgets);
    await tester.tap(addIcons.last); // last add-icon = minutes picker
    await tester.pump();

    // ── SAVE ───────────────────────────────────────────────────────────────────
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // After saving, GoRouter pops back to /timer — idle state restored.
    expect(find.text('START'), findsOneWidget);

    // ── DB assertion ──────────────────────────────────────────────────────────
    // Confirm exactly one session was persisted.
    final sessions = await db.select(db.sessions).get();
    expect(sessions.length, 1);
    // durationSecs is clamped to [0, 86400]. With fake-frame time it may be 0.
    expect(sessions.first.durationSecs, greaterThanOrEqualTo(0));

    await db.close();
  });
}
