// Copy to: <flutter_project>/test/flutter_test_config.dart
// (auto-loaded by `flutter test` for every test under test/)
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the real Roboto + Material Icons fonts into the test font manager so
/// golden PNGs show readable text instead of the placeholder black boxes that
/// Flutter renders by default. Fonts are resolved from the active Flutter SDK's
/// font cache (nothing is vendored into the repo); if they can't be found,
/// tests still run — text just falls back to boxes.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadRealFonts();
  return testMain();
}

Future<void> _loadRealFonts() async {
  final Directory? fontsDir = _materialFontsDir();
  if (fontsDir == null) return;

  ByteData? read(String name) {
    final File f = File('${fontsDir.path}/$name');
    if (!f.existsSync()) return null;
    return ByteData.view(Uint8List.fromList(f.readAsBytesSync()).buffer);
  }

  Future<void> load(String family, List<String> files) async {
    final FontLoader loader = FontLoader(family);
    bool any = false;
    for (final String file in files) {
      final ByteData? data = read(file);
      if (data != null) {
        loader.addFont(Future<ByteData>.value(data));
        any = true;
      }
    }
    if (any) await loader.load();
  }

  await load('Roboto', <String>[
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Light.ttf',
  ]);
  await load('MaterialIcons', <String>['MaterialIcons-Regular.otf']);
}

/// Resolves the active Flutter SDK's `material_fonts` cache directory.
Directory? _materialFontsDir() {
  final List<String> candidates = <String>[];

  final String? root = Platform.environment['FLUTTER_ROOT'];
  if (root != null && root.isNotEmpty) {
    candidates.add('$root/bin/cache/artifacts/material_fonts');
  }

  // Tests run on the Flutter-bundled Dart at <flutter>/bin/cache/dart-sdk/bin/dart,
  // so <flutter>/bin/cache is three parents up from the executable.
  try {
    final Directory cache =
        File(Platform.resolvedExecutable).parent.parent.parent;
    candidates.add('${cache.path}/artifacts/material_fonts');
  } catch (_) {}

  for (final String c in candidates) {
    final Directory d = Directory(c);
    if (d.existsSync()) return d;
  }
  return null;
}
