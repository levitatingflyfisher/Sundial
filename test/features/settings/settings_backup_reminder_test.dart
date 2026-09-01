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
import 'package:sundial/features/settings/presentation/settings_screen.dart';

/// Ruling 48: the app opens straight into the task, and unfinished backup
/// setup gets a dismissible "finish setup" line so it is never forgotten.
/// Sundial puts it at the top of Settings, not on the timer: "inform, never
/// nag" (AGENTS.md).
void main() {
  const acked = 'abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon abandon abandon about';

  Future<Widget> screen(SecureKeyStore store) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: [
        appDatabaseProvider
            .overrideWith((_) => AppDatabase(NativeDatabase.memory())),
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
        backupReminderStoreProvider
            .overrideWithValue(InMemoryBackupReminderStore()),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  const notSetUp = "Backup isn't set up. Your data is only on this device.";

  testWidgets('no backup yet: the line shows, and Dismiss puts it away',
      (tester) async {
    await tester.pumpWidget(await screen(InMemorySecureKeyStore()));
    await tester.pumpAndSettle();

    expect(find.text(notSetUp), findsOneWidget);
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text(notSetUp), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  testWidgets('setup finished: no line', (tester) async {
    await tester.pumpWidget(await screen(
        InMemorySecureKeyStore(mnemonic: acked, acknowledged: true)));
    await tester.pumpAndSettle();

    // skipOffstage: false because the finished-state reminder renders a
    // zero-size SizedBox, which the default finder treats as offstage.
    expect(find.byType(BackupSetupReminder, skipOffstage: false),
        findsOneWidget);
    expect(find.text(notSetUp), findsNothing);
    expect(find.textContaining('Finish backup setup'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
