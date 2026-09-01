import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sundial/core/error/failures.dart';
import 'package:sundial/features/sessions/domain/sessions_repository.dart';
import 'package:sundial/features/sessions/presentation/session_edit_sheet.dart';
import 'package:sundial/features/timer/domain/timer_state.dart';
import 'package:sundial/features/timer/presentation/timer_notifier.dart';

class _FailingSessionsRepo implements SessionsRepository {
  @override
  Future<Either<StorageFailure, Unit>> saveSession(Session s) async =>
      const Left(StorageFailure('disk full'));
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// about-face-11: change the duration, date or notes in Edit Session, tap
/// back, and the edit vanished without a word. Back now keeps the work: it
/// saves through the same path as Save. No "Save changes?" dialog, which the
/// finding rules out as well.
void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  final session = Session(
    id: 's1',
    startTime: DateTime(2026, 3, 28, 9).millisecondsSinceEpoch,
    endTime: DateTime(2026, 3, 28, 10).millisecondsSinceEpoch,
    durationSecs: 3600,
    dateDay: '2026-03-28',
    createdAt: 0,
    updatedAt: 0,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
    await db.into(db.sessions).insert(session.toCompanion(true));
  });

  Future<void> openEditor(WidgetTester tester,
      {List<Override> extra = const []}) async {
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/edit'),
            child: const Text('open'),
          ),
        ),
      ),
      GoRoute(
        path: '/edit',
        builder: (_, __) =>
            SessionEditSheet(sessionId: session.id, initialSession: session),
      ),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((_) => db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...extra,
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  // Drift runs on real I/O: let the save started by back finish, then
  // settle the pop.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();
    }
  }

  Future<Session> stored() async =>
      (await db.select(db.sessions).get()).single;

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await db.close();
  }

  testWidgets('app-bar back saves a typed note', (tester) async {
    await openEditor(tester);
    await tester.enterText(find.byType(TextFormField), 'park day');
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    expect(find.text('open'), findsOneWidget, reason: 'the editor closed');
    expect(find.byType(AlertDialog), findsNothing);
    expect((await tester.runAsync(stored))!.notes, 'park day');
    await drain(tester);
  });

  testWidgets('system back saves a typed note', (tester) async {
    await openEditor(tester);
    await tester.enterText(find.byType(TextFormField), 'creek walk');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await settle(tester);

    expect(find.text('open'), findsOneWidget);
    expect((await tester.runAsync(stored))!.notes, 'creek walk');
    await drain(tester);
  });

  testWidgets('back with nothing changed writes nothing', (tester) async {
    await openEditor(tester);
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    expect(find.text('open'), findsOneWidget);
    expect((await tester.runAsync(stored))!.updatedAt, 0);
    await drain(tester);
  });

  testWidgets('a failed save does not trap the user behind back',
      (tester) async {
    await openEditor(tester, extra: [
      sessionsRepositoryProvider.overrideWith((_) => _FailingSessionsRepo()),
    ]);
    await tester.enterText(find.byType(TextFormField), 'park day');
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    expect(find.text('open'), findsOneWidget, reason: 'back still leaves');
    expect(find.textContaining('Edit not saved'), findsOneWidget);
    await drain(tester);
  });

  testWidgets(
      'editing another session while a draft is unsaved never swallows the '
      'draft', (tester) async {
    await openEditor(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(Scaffold).last));
    // In the app the Timer screen under this route keeps the (auto-dispose)
    // timer provider alive; stand in for it.
    final keepAlive = container.listen(timerNotifierProvider, (_, __) {});
    addTearDown(keepAlive.close);
    final notifier = container.read(timerNotifierProvider.notifier);
    await tester.runAsync(() async {
      await notifier.start();
      await notifier.buildDraftSession();
    });
    final draft = container.read(timerNotifierProvider);
    expect(draft, isA<TimerStopped>());

    await tester.enterText(find.byType(TextFormField), 'park day');
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    expect(container.read(timerNotifierProvider), same(draft),
        reason: 'the edited session is not the draft');
    expect((await tester.runAsync(stored))!.notes, 'park day');
    await drain(tester);
  });
}
