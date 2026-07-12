// Facade for writing the encrypted backup (.ohbk) to a device file.
// Resolves to the native implementation (dart:io + path_provider) on all
// platforms except web, which gets a throwing stub whose call site (the
// "Save to device" icon in export_screen.dart) is hidden via
// [backupSaveToDeviceSupported] — so an unconditional dart:io File write is
// never reachable on the web build (F15: the .ohbk 'Save' path must not
// bypass the conditional-import trio used elsewhere for native-only file
// I/O, e.g. Trellis's anki_export.dart).
export 'backup_file_save_io.dart'
    if (dart.library.html) 'backup_file_save_web.dart';
