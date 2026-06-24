import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/sessions/presentation/manual_entry_sheet.dart';

/// Pumps ManualEntrySheet inside a minimal GoRouter so `context.pop()` works.
/// Returns the AppDatabase the test can query after tapping Save.
Future<AppDatabase> _pumpSheet(
  WidgetTester tester, {
  required String activeProfileId,
  List<({String id, String name})> extraProfiles = const [],
}) async {
  SharedPreferences.setMockInitialValues({
    'active_profile_id': activeProfileId,
  });
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());

  // Seed any extra profiles beyond the 'default' one the migration inserts.
  // Named profiles are required because sessions.profileId is an FK.
  for (final p in extraProfiles) {
    await db.into(db.profiles).insert(
          ProfilesCompanion.insert(
            id: p.id,
            name: p.name,
            colorValue: 0xFF5E9478,
            createdAt: 0,
            sortOrder: const Value(0),
          ),
        );
  }

  final router = GoRouter(
    initialLocation: '/add',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: '/add',
        builder: (_, __) => const ManualEntrySheet(),
      ),
    ],
  );

  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWith((_) => db),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  return db;
}

void main() {
  group('ManualEntrySheet profile attribution', () {
    testWidgets(
        'saves with profileId=null when active profile is Everyone',
        (tester) async {
      final db = await _pumpSheet(tester, activeProfileId: kEveryoneProfileId);

      // Default duration is 0h 30m — above the > 0 guard.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final sessions = await db.select(db.sessions).get();
      expect(sessions, hasLength(1));
      expect(sessions.first.profileId, isNull,
          reason: 'Everyone sessions must store profileId=null so they count '
              'for every profile without double-counting');
    });

    testWidgets(
        'saves with profileId=<active> when a named profile is active',
        (tester) async {
      final db = await _pumpSheet(
        tester,
        activeProfileId: 'dad',
        extraProfiles: const [(id: 'dad', name: 'Dad')],
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final sessions = await db.select(db.sessions).get();
      expect(sessions, hasLength(1));
      expect(sessions.first.profileId, 'dad');
    });

    testWidgets(
        'saves with profileId=default when default profile is active',
        (tester) async {
      final db = await _pumpSheet(tester, activeProfileId: 'default');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final sessions = await db.select(db.sessions).get();
      expect(sessions, hasLength(1));
      expect(sessions.first.profileId, 'default');
    });
  });
}
