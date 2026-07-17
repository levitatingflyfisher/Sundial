// Web-honesty tests for ExportScreen: every affordance visible on a platform
// must either work there or not be shown (the bug class: a button that
// silently does nothing on the live PWA).
//
// The platform split is the same conditional-import trio seam the encrypted
// .ohbk save uses (F15, backup_file_save*.dart) — surfaced through
// [saveToDeviceSupportedProvider] so a VM widget test can fake the web
// resolution (the raw top-level getter is compile-time and always io here).

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
  List<Override> extraOverrides = const [],
}) async {
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
      backupSerializerProvider.overrideWithValue(FakeBackupSerializer()),
      vaultStoreProvider.overrideWithValue(InMemoryVaultStore()),
      ...extraOverrides,
    ],
    child: const MaterialApp(home: ExportScreen()),
  );
}

void main() {
  group('ExportScreen — save-to-device honesty', () {
    testWidgets(
        'platforms with device saves (io) show Save buttons on the '
        'plaintext and JSON export tiles', (tester) async {
      final store = InMemorySecureKeyStore();
      await tester.pumpWidget(await _makeScreen(store: store));
      await tester.pumpAndSettle();

      // Plaintext + JSON tiles each carry one Save-to-device button.
      expect(find.byTooltip('Save to device'), findsNWidgets(2));
    });

    testWidgets(
        'when the platform cannot save to device (web), the plaintext and '
        'JSON Save buttons are not shown at all — never a button that fails',
        (tester) async {
      final store = InMemorySecureKeyStore();
      await tester.pumpWidget(await _makeScreen(
        store: store,
        extraOverrides: [
          saveToDeviceSupportedProvider.overrideWithValue(false),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Save to device'), findsNothing);
      // Share stays available on every platform.
      expect(find.byTooltip('Share'), findsWidgets);
    });

    testWidgets(
        'the encrypted .ohbk Save icon respects the same seam (F15) — '
        'hidden when unsupported, Share still offered', (tester) async {
      final store =
          InMemorySecureKeyStore(mnemonic: _ackedMnemonic, acknowledged: true);
      await tester.pumpWidget(await _makeScreen(
        store: store,
        extraOverrides: [
          saveToDeviceSupportedProvider.overrideWithValue(false),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Encrypted backup (.ohbk)'), findsOneWidget);
      expect(find.byTooltip('Save to device'), findsNothing);
      expect(find.byTooltip('Share'), findsWidgets);
    });

    testWidgets(
        'the encrypted .ohbk Save icon is shown where device saves work',
        (tester) async {
      final store =
          InMemorySecureKeyStore(mnemonic: _ackedMnemonic, acknowledged: true);
      await tester.pumpWidget(await _makeScreen(store: store));
      await tester.pumpAndSettle();

      // Plaintext + JSON + .ohbk.
      expect(find.byTooltip('Save to device'), findsNWidgets(3));
    });
  });
}
