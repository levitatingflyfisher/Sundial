import 'dart:typed_data';

/// Whether "Save to device" is available on this platform (false on web —
/// dart:io file writes aren't; export_screen.dart hides the Save icon and
/// offers Share only, matching the fleet's io/web split convention).
bool get backupSaveToDeviceSupported => false;

Future<String> saveBackupBytesToDevice(Uint8List bytes, String filename) =>
    throw UnsupportedError(
        'Save to device is unavailable on web; use Share instead.');

Future<String> saveTextToDevice(String content, String filename) =>
    throw UnsupportedError(
        'Save to device is unavailable on web; use Share instead.');
