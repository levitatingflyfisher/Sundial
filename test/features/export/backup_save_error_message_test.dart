// F11: a "Save to device" failure for the encrypted backup must show calm,
// specific copy — never the raw exception text (a PathAccessException's
// `toString()` can include the OS error and a filesystem path).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/export/presentation/export_screen.dart';

void main() {
  group('backupSaveErrorMessage', () {
    test('never echoes the raw exception text', () {
      const raw = FileSystemException(
          'Cannot open file', '/storage/emulated/0/secret-path/x.ohbk');

      final message = backupSaveErrorMessage(raw);

      expect(message, isNot(contains('/storage/emulated/0')));
      expect(message, isNot(contains('FileSystemException')));
      expect(message, isNot(startsWith('Save failed:')));
    });

    test('permission errors get a specific, calm message', () {
      final raw = Exception('PathAccessException: permission denied');

      final message = backupSaveErrorMessage(raw);

      expect(message, contains('permission'));
      expect(message, contains('Try Share instead'));
    });

    test('missing-plugin (e.g. web) errors get a specific message', () {
      final raw = Exception('MissingPluginException(no implementation)');

      final message = backupSaveErrorMessage(raw);

      expect(message, contains("isn't available here"));
      expect(message, contains('Try Share instead'));
    });

    test('any other failure falls back to a calm generic message', () {
      final message = backupSaveErrorMessage(Exception('disk is on fire'));

      expect(message, isNot(contains('disk is on fire')));
      expect(message, contains('Try Share instead'));
    });
  });
}
