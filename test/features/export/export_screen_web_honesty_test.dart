// Web-honesty tests for ExportScreen: every affordance visible on a platform
// must either work there or not be shown (the bug class: a button that
// silently does nothing on the live PWA).
//
// The platform split is the same conditional-import trio seam the encrypted
// .ohbk save uses (F15, backup_file_save*.dart) — surfaced through
// [saveToDeviceSupportedProvider] so a VM widget test can fake the web
// resolution (the raw top-level getter is compile-time and always io here).

import 'dart:convert';
import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:sanctuary_backup_ui/testing.dart';
// The platform interface is a real (dev) dependency here: faking the share
// target means replacing SharePlatform.instance, which share_plus itself
// does not re-export.
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/export/presentation/export_screen.dart';

/// Records the shareXFiles call the export tiles make. Extending
/// [SharePlatform] (not the method channel) keeps the platform-interface
/// token valid and never touches a real channel.
class _RecordingSharePlatform extends SharePlatform {
  List<XFile>? files;
  List<String>? fileNameOverrides;
  String? text;

  @override
  Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
    List<String>? fileNameOverrides,
  }) async {
    this.files = files;
    this.fileNameOverrides = fileNameOverrides;
    this.text = text;
    return const ShareResult('recorded', ShareResultStatus.success);
  }
}

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

  group('ExportScreen — share works from bytes (no temp-file write)', () {
    late _RecordingSharePlatform share;
    late SharePlatform previous;

    setUp(() {
      previous = SharePlatform.instance;
      share = _RecordingSharePlatform();
      SharePlatform.instance = share;
    });

    tearDown(() => SharePlatform.instance = previous);

    Finder shareButtonOf(String tileTitle) => find.descendant(
          of: find.ancestor(
            of: find.text(tileTitle),
            matching: find.byType(ListTile),
          ),
          matching: find.byTooltip('Share'),
        );

    testWidgets(
        'JSON Share hands share_plus in-memory bytes with a filename '
        'override — never a dart:io temp file, so it works on web too',
        (tester) async {
      await tester.pumpWidget(
          await _makeScreen(store: InMemorySecureKeyStore()));
      await tester.pumpAndSettle();

      // runAsync: building the JSON awaits real drift stream futures, which
      // never complete under the fake-async pump loop alone.
      await tester.runAsync(() async {
        await tester.tap(shareButtonOf('JSON'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(share.files, isNotNull,
          reason: 'Share must reach share_plus instead of dying on a '
              'temp-file write beforehand');
      expect(share.files, hasLength(1));
      expect(share.fileNameOverrides, ['sundial-backup.json']);
      expect(share.files!.single.mimeType, 'application/json');
      final decoded = utf8.decode(await share.files!.single.readAsBytes());
      expect(decoded, contains('"version"'),
          reason: 'the shared bytes are the JSON export itself');
    });

    testWidgets('Plaintext Share does the same with text/plain',
        (tester) async {
      await tester.pumpWidget(
          await _makeScreen(store: InMemorySecureKeyStore()));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(shareButtonOf('Plaintext (.sundial)'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(share.files, isNotNull);
      expect(share.fileNameOverrides, ['sundial-backup.sundial']);
      expect(share.files!.single.mimeType, 'text/plain');
    });
  });
}
