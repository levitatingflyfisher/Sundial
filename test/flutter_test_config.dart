// Copy to: <flutter_project>/test/flutter_test_config.dart
// (auto-loaded by `flutter test` for every test under test/)
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads real fonts so golden PNGs show readable text instead of the
/// placeholder boxes Flutter renders by default:
///  1. the app's OWN bundled fonts (e.g. openhearth_design's Lora / Nunito)
///     from its asset manifest — so goldens show the real design-system type;
///  2. the SDK Roboto + Material Icons as the default-family fallback.
/// Both are best-effort: if fonts can't be found, tests still run (text just
/// falls back to boxes).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadAppBundledFonts();
  await _loadSdkFonts();
  return testMain();
}

/// Loads every font the app declares in its pubspec (via FontManifest.json),
/// so goldens render the app's real bundled type. No-op if the app bundles no
/// fonts. This is what makes design-system fonts (Lora/Nunito/JetBrains Mono)
/// render instead of boxes.
Future<void> _loadAppBundledFonts() async {
  final List<dynamic> families;
  try {
    final String manifest = await rootBundle.loadString('FontManifest.json');
    families = json.decode(manifest) as List<dynamic>;
  } catch (_) {
    // No FontManifest (app bundles no fonts) — fine.
    return;
  }
  for (final dynamic entry in families) {
    // Each family is guarded on its own: one family's failure (bad asset
    // path, corrupt font) logs and continues instead of aborting the
    // families after it — MaterialIcons loads first, so an unguarded
    // failure there would silently kill Lora/Nunito.
    try {
      final Map<String, dynamic> e = entry as Map<String, dynamic>;
      final String? family = e['family'] as String?;
      final List<dynamic>? fonts = e['fonts'] as List<dynamic>?;
      if (family == null || fonts == null) continue;
      final FontLoader loader = FontLoader(family);
      for (final dynamic f in fonts) {
        final String? asset = (f as Map<String, dynamic>)['asset'] as String?;
        if (asset != null) loader.addFont(rootBundle.load(asset));
      }
      await loader.load();
    } catch (e) {
      // ignore: avoid_print
      print('flutter_test_config: skipped a font family that failed to '
          'load: $e');
    }
  }
}

/// Loads the active Flutter SDK's Roboto + Material Icons as the default family
/// (covers apps that use the Material default type, and Material icons).
Future<void> _loadSdkFonts() async {
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
