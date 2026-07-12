import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Whether "Save to device" is available on this platform (true here — the
/// native, dart:io-backed implementation).
bool get backupSaveToDeviceSupported => true;

/// Writes [bytes] to a device file named [filename] and returns the full
/// path it was written to.
Future<String> saveBackupBytesToDevice(Uint8List bytes, String filename) async {
  Directory? dir;
  try {
    dir = await getExternalStorageDirectory();
  } catch (_) {}
  dir ??= await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}
