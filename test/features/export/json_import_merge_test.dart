// Audit finding 7 / ruling Q-D2: "Import from JSON" upserted sessions,
// profiles and badges and overwrote the goal with no read-back and no way
// back. Import is Merge only: it first says what the file would change
// against what this phone holds (new sessions, sessions it would update,
// the goal from X to Y) and asks once; on Merge it takes a safety copy into
// Previous backups when backup is set up, and writes nothing if that copy
// fails.

import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:sanctuary_backup_ui/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/export/presentation/export_screen.dart';

const _ackedMnemonic = 'abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon abandon abandon about';

Map<String, Object?> _session(String id, int dur, {String? notes}) => {
      'id': id,
      'start_time': 1000,
      'end_time': 1000 + dur * 1000,
      'duration_secs': dur,
      'date_day': '2026-09-01',
      if (notes != null) 'notes': notes,
      'created_at': 1000,
      'updated_at': 1000,
    };

Uint8List _file({int goal = 500}) => Uint8List.fromList(utf8.encode(jsonEncode({
      'version': 3,
      'annual_goal_hours': goal,
      'sessions': [
        _session('same', 600),
        _session('changed', 1800, notes: 'longer than here'),
        _session('new1', 300),
        _session('new2', 900),
      ],
      'profiles': [],
      'badges': [],
    })));

void main() {
  late AppDatabase db;
  late InMemoryVaultStore vault;

  Future<void> seedPhone() async {
    for (final (id, dur) in [('same', 600), ('changed', 1200)]) {
      await db.into(db.sessions).insert(SessionsCompanion.insert(
            id: id,
            startTime: 1000,
            endTime: 1000 + dur * 1000,
            durationSecs: dur,
            dateDay: '2026-09-01',
            createdAt: 1000,
            updatedAt: 1000,
          ));
    }
  }

  Future<void> pump(WidgetTester tester, SecureKeyStore store,
      {Uint8List? bytes}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
    vault = InMemoryVaultStore();
    await tester.runAsync(seedPhone);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((_) => db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        secureKeyStoreProvider.overrideWithValue(store),
        cryptoServiceProvider.overrideWithValue(FakeCryptoService()),
        sanctuaryAppDomainProvider.overrideWithValue('sundial'),
        sanctuaryBackupConfigProvider.overrideWithValue(
          const SanctuaryBackupConfig(
            appId: 'sundial',
            aadContext: 'sundial-backup/v1',
            appDisplayName: 'Sundial',
          ),
        ),
        backupSerializerProvider.overrideWithValue(FakeBackupSerializer()),
        vaultStoreProvider.overrideWithValue(vault),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => importJsonBytes(context, ref, bytes ?? _file()),
              child: const Text('import'),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<List<Session>> sessions(WidgetTester tester) async =>
      (await tester.runAsync(() => db.select(db.sessions).get()))!;

  Future<void> tapAndSettle(WidgetTester tester, Finder f) async {
    await tester.runAsync(() async {
      await tester.tap(f);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    // Reads, the safety copy and the writes are real async work: let it
    // interleave with frames.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('the preview says what would change; Cancel writes nothing',
      (tester) async {
    await pump(tester, InMemorySecureKeyStore());
    await tapAndSettle(tester, find.text('import'));

    expect(find.text('Merge this file?'), findsOneWidget);
    expect(find.textContaining('Adds 2 sessions'), findsOneWidget);
    expect(find.textContaining('updates 1 already here'), findsOneWidget);
    expect(find.textContaining('1000h to 500h'), findsOneWidget);

    await tapAndSettle(tester, find.text('Cancel'));
    final rows = await sessions(tester);
    expect(rows.map((s) => s.id).toSet(), {'same', 'changed'});
    expect(rows.firstWhere((s) => s.id == 'changed').durationSecs, 1200);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Merge without backup adds and updates, and says so',
      (tester) async {
    await pump(tester, InMemorySecureKeyStore());
    await tapAndSettle(tester, find.text('import'));
    await tapAndSettle(tester, find.text('Merge the file'));

    final rows = await sessions(tester);
    expect(rows.map((s) => s.id).toSet(), {'same', 'changed', 'new1', 'new2'});
    expect(rows.firstWhere((s) => s.id == 'changed').durationSecs, 1800);
    expect(await tester.runAsync(() => vault.list()), isEmpty);
    expect(find.textContaining('Merged'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('with backup set up, a safety copy is taken before the merge',
      (tester) async {
    await pump(tester,
        InMemorySecureKeyStore(mnemonic: _ackedMnemonic, acknowledged: true));
    await tapAndSettle(tester, find.text('import'));
    await tapAndSettle(tester, find.text('Merge the file'));

    expect(await tester.runAsync(() => vault.list()), hasLength(1));
    expect(find.textContaining('Previous backups'), findsOneWidget);
    expect((await sessions(tester)).length, 4);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a file with nothing new asks nothing and writes nothing',
      (tester) async {
    final same = Uint8List.fromList(utf8.encode(jsonEncode({
      'version': 3,
      'sessions': [_session('same', 600)],
      'profiles': [],
      'badges': [],
    })));
    await pump(tester, InMemorySecureKeyStore(), bytes: same);
    await tapAndSettle(tester, find.text('import'));
    expect(find.text('Merge this file?'), findsNothing);
    expect(find.textContaining('Nothing in this file'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  // Re-importing your own backup is the common case: profiles and badges
  // the phone already has are not news, and the preview must not ask.
  testWidgets('profiles and earned badges already here are not counted',
      (tester) async {
    final own = Uint8List.fromList(utf8.encode(jsonEncode({
      'version': 3,
      'sessions': [_session('same', 600)],
      'profiles': [
        {
          'id': 'p1',
          'name': 'Ada',
          'color_value': 0xFF7A9E7E,
          'sort_order': 0,
          'created_at': 1000,
        }
      ],
      'badges': [
        {'id': 'b10', 'earned_at': 5000}
      ],
    })));
    await pump(tester, InMemorySecureKeyStore(), bytes: own);
    await tester.runAsync(() async {
      await db.into(db.profiles).insert(ProfilesCompanion.insert(
            id: 'p1',
            name: 'Ada',
            colorValue: 0xFF7A9E7E,
            createdAt: 1000,
          ));
      await db.into(db.badges).insertOnConflictUpdate(BadgesCompanion.insert(
            id: 'b10',
            thresholdHours: 10,
            earnedAt: const Value(5000),
          ));
    });
    await tapAndSettle(tester, find.text('import'));
    expect(find.text('Merge this file?'), findsNothing);
    expect(find.textContaining('Nothing in this file'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
