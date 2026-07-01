// Config regression-guard, not behavioral: asserts the Android manifest
// opts OUT of OS/cloud backup. There is no way to drive Android Auto Backup
// from `flutter test`, so this pins the config that disables it.
//
// Why it matters: Android's default allowBackup=true silently enrolls the
// unencrypted Drift database (session notes, profile names) and
// FlutterSharedPreferences into Google cloud backup / device-to-device
// transfer — violating the local-first / cloud-is-opt-in invariant. The
// sanctioned backup path is the explicit, user-driven export flow.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android backup opt-out', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    test('manifest disables allowBackup', () {
      expect(
        manifest,
        contains('android:allowBackup="false"'),
        reason: 'without allowBackup="false" the OS default (true) uploads '
            'the plaintext Drift DB to Google cloud backup',
      );
    });

    test('manifest disables legacy full-backup content (pre-Android-12)', () {
      expect(
        manifest,
        contains('android:fullBackupContent="false"'),
        reason: 'pre-Android-12 devices honor fullBackupContent, not '
            'dataExtractionRules',
      );
    });

    test('manifest wires dataExtractionRules (Android 12+)', () {
      expect(
        manifest,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );
    });

    test('data_extraction_rules.xml excludes everything from cloud backup '
        'and device transfer', () {
      final rulesFile =
          File('android/app/src/main/res/xml/data_extraction_rules.xml');
      expect(rulesFile.existsSync(), isTrue,
          reason: 'the manifest must reference a rules file that exists');
      final rules = rulesFile.readAsStringSync();
      expect(rules, contains('<cloud-backup>'));
      expect(rules, contains('<device-transfer>'));
      for (final domain in ['file', 'database', 'sharedpref', 'external']) {
        expect(rules, contains('<exclude domain="$domain" />'),
            reason: 'domain "$domain" must be excluded from backup/transfer');
      }
    });
  });
}
