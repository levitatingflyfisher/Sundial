// Copy to: <flutter_project>/test/flutter_test_config.dart
// (auto-loaded by `flutter test` for every test under test/)
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the real Roboto + Material Icons fonts into the test font manager so
/// golden PNGs show readable text instead of the placeholder black boxes that
/// Flutter renders by default. Fonts are resolved from the active Flutter SDK's
/// font cache (nothing is vendored into the repo); if they can't be found,
/// tests still run — text just falls back to boxes.
///
/// The app's own bundled families (Lora/Nunito, declared in pubspec `fonts:`)
/// are loaded too, from the repo's assets/fonts/ — `flutter test` does NOT
/// load pubspec-declared asset fonts automatically, so without this every
/// AppTextStyles run (fontFamily 'Lora'/'Nunito') renders as Ahem boxes while
/// theme text (Roboto) renders for real, and goldens silently depend on which
/// families happened to load when they were generated.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadRealFonts();
  await _loadBundledFonts();
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

/// Loads the app's bundled font families from assets/fonts/ (repo-relative;
/// `flutter test` runs with the package root as CWD). Same soft-fail contract
/// as [_loadRealFonts]: missing files just mean boxes, never a test error.
Future<void> _loadBundledFonts() async {
  const Map<String, List<String>> families = <String, List<String>>{
    'Lora': <String>[
      'Lora-Regular.ttf',
      'Lora-Italic.ttf',
      'Lora-Medium.ttf',
      'Lora-Bold.ttf',
    ],
    'Nunito': <String>[
      'Nunito-Regular.ttf',
      'Nunito-Medium.ttf',
      'Nunito-SemiBold.ttf',
      'Nunito-Bold.ttf',
    ],
  };

  for (final MapEntry<String, List<String>> family in families.entries) {
    final FontLoader loader = FontLoader(family.key);
    bool any = false;
    for (final String name in family.value) {
      final File f = File('assets/fonts/$name');
      if (!f.existsSync()) continue;
      loader.addFont(Future<ByteData>.value(
          ByteData.view(Uint8List.fromList(f.readAsBytesSync()).buffer)));
      any = true;
    }
    if (any) await loader.load();
  }
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
