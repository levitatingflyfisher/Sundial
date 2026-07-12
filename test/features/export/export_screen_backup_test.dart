// Widget tests for the encrypted-backup (.ohbk) section hosted on
// ExportScreen (SANCTUARY-BRIEF §4.W2 app-specific block: integrate .ohbk
// INTO the existing Backup & Restore screen, not a separate settings
// section).

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

Future<Widget> _makeScreen({
  required SecureKeyStore store,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((_) => AppDatabase(NativeDatabase.memory())),
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
    ],
    child: const MaterialApp(home: ExportScreen()),
  );
}

void main() {
  group('ExportScreen — encrypted backup section', () {
    testWidgets('shows "Set up encrypted backup" when no key exists',
        (tester) async {
      final store = InMemorySecureKeyStore();
      await tester.pumpWidget(await _makeScreen(store: store));
      await tester.pumpAndSettle();

      expect(find.text('Set up encrypted backup'), findsOneWidget);
      expect(find.text('Encrypted backup (.ohbk)'), findsNothing);
    });

    testWidgets('shows the encrypted export tile once seed is acknowledged',
        (tester) async {
      final store =
          InMemorySecureKeyStore(mnemonic: _ackedMnemonic, acknowledged: true);
      await tester.pumpWidget(await _makeScreen(store: store));
      await tester.pumpAndSettle();

      expect(find.text('Encrypted backup (.ohbk)'), findsOneWidget);
      expect(find.text('Set up encrypted backup'), findsNothing);
    });

    testWidgets('shows the restore-from-encrypted-backup entry always',
        (tester) async {
      final store = InMemorySecureKeyStore();
      await tester.pumpWidget(await _makeScreen(store: store));
      await tester.pumpAndSettle();

      expect(find.text('Restore from encrypted backup'), findsOneWidget);
    });

    testWidgets('existing plaintext/JSON/PDF export options are unaffected',
        (tester) async {
      final store = InMemorySecureKeyStore();
      await tester.pumpWidget(await _makeScreen(store: store));
      await tester.pumpAndSettle();

      expect(find.text('Plaintext (.sundial)'), findsOneWidget);
      expect(find.text('JSON'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('Import from JSON'), findsOneWidget);
    });

    testWidgets('no overflow at 320dp x textScale 3.0 (no key yet)',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(320, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final store = InMemorySecureKeyStore();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
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
            backupSerializerProvider.overrideWithValue(FakeBackupSerializer()),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(3.0)),
              child: child!,
            ),
            home: const ExportScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull,
          reason: 'no RenderFlex overflow at narrow width + large text scale');
    });

    testWidgets(
        'no overflow at 320dp x textScale 3.0 (key set up + acknowledged)',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(320, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final store =
          InMemorySecureKeyStore(mnemonic: _ackedMnemonic, acknowledged: true);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
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
            backupSerializerProvider.overrideWithValue(FakeBackupSerializer()),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(3.0)),
              child: child!,
            ),
            home: const ExportScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull,
          reason: 'no RenderFlex overflow at narrow width + large text scale');
    });
  });
}
