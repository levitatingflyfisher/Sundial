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
import 'package:sundial/features/flow_mode/presentation/sundial_face.dart';
import 'package:sundial/features/profiles/presentation/profiles_screen.dart';
import 'package:sundial/features/sessions/presentation/manual_entry_sheet.dart';
import 'package:sundial/features/sessions/presentation/session_edit_sheet.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';

/// On a tablet or a desktop browser the phone layout must not stretch edge to
/// edge: content is capped (OhPage, 640dp) and centred, while app bars and
/// the bottom bar stay full width.
const _wide = Size(1024, 900);
const _cap = OhPage.phoneMaxWidth;

void _expectCentredAndCapped(WidgetTester tester, Finder f) {
  final r = tester.getRect(f);
  expect(r.width, lessThanOrEqualTo(_cap), reason: 'content is capped');
  expect(r.center.dx, moreOrLessEquals(_wide.width / 2, epsilon: 1),
      reason: 'content is centred');
}

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

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

  Widget scope(Widget child, {AppMode mode = AppMode.rich}) => ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWith((_) => db),
          appModeProvider.overrideWith((_) => Stream.value(mode)),
        ],
        child: child,
      );

  Widget shell(AppMode mode) => scope(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/timer',
            routes: [
              ShellRoute(
                builder: (context, state, child) => AppShell(child: child),
                routes: [
                  GoRoute(
                    path: '/timer',
                    builder: (_, __) =>
                        const SizedBox.expand(key: Key('tab-content')),
                  ),
                ],
              ),
            ],
          ),
        ),
        mode: mode,
      );

  testWidgets('Rich tabs: content capped and centred, bars full width',
      (tester) async {
    await tester.binding.setSurfaceSize(_wide);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(shell(AppMode.rich));
    await tester.pump(const Duration(milliseconds: 100));

    _expectCentredAndCapped(tester, find.byKey(const Key('tab-content')));
    expect(tester.getSize(find.byType(AppBar)).width, _wide.width);
    expect(tester.getSize(find.byType(NavigationBar)).width, _wide.width);
    await drain(tester);
  });

  testWidgets('Flow: the face is capped and centred', (tester) async {
    await tester.binding.setSurfaceSize(_wide);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(shell(AppMode.flow));
    await tester.pump(const Duration(milliseconds: 100));

    _expectCentredAndCapped(tester, find.byType(SundialFace));
    expect(tester.getSize(find.byType(AppBar)).width, _wide.width);
    await drain(tester);
  });

  for (final entry in <String, Widget>{
    'People': const ProfilesScreen(),
    'Add Time': const ManualEntrySheet(),
    'Edit Session': const SessionEditSheet(sessionId: 'x'),
  }.entries) {
    testWidgets('${entry.key}: content capped and centred', (tester) async {
      await tester.binding.setSurfaceSize(_wide);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(scope(MaterialApp(home: entry.value)));
      await tester.pump(const Duration(milliseconds: 100));

      _expectCentredAndCapped(tester, find.byType(ListView).first);
      expect(tester.getSize(find.byType(AppBar)).width, _wide.width);
      await drain(tester);
    });
  }
}
