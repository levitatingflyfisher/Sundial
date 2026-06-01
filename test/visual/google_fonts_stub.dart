import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Makes `GoogleFonts.lora/nunito/...` resolve *synchronously from assets* in a
/// headless golden test, instead of attempting a (failing, throwing) network
/// fetch from fonts.gstatic.com.
///
/// Why this is needed: widgets that build their `TextStyle`s via the
/// `google_fonts` package (Sundial's `AppTextStyles`) schedule an async font
/// load at build time. A golden helper that `pumpAndSettle()`s *awaits* that
/// load, and since the headless test can't reach the network the rejected
/// future surfaces as a thrown exception that fails the test.
///
/// The fix mirrors the package's own asset-loading path: with runtime fetching
/// disabled, `loadFontIfNecessary` looks the requested family up in the asset
/// `AssetManifest.bin` and loads its bytes. We mock that manifest to declare
/// the Lora/Nunito variants Sundial requests, pointing each at the SDK Roboto
/// TTF (already loaded by flutter_test_config.dart). The font then renders as
/// Roboto — the exact same substitution the rest of the visual suite uses —
/// while exercising the real widget layout/render path.
///
/// Call once in a test's body before pumping. Restores config on teardown.
void stubGoogleFontsWithRoboto(WidgetTester tester) {
  GoogleFonts.config.allowRuntimeFetching = false;
  addTearDown(() => GoogleFonts.config.allowRuntimeFetching = true);

  final Uint8List robotoBytes = _robotoBytes();
  if (robotoBytes.isEmpty) return; // No SDK fonts found; nothing we can do.

  // Asset keys google_fonts will match (it matches by the `Family-Variant`
  // filename prefix, so any path ending in these names works).
  const List<String> fontAssets = <String>[
    'assets/gf_stub/Lora-Bold.ttf',
    'assets/gf_stub/Lora-Regular.ttf',
    'assets/gf_stub/Nunito-Medium.ttf',
    'assets/gf_stub/Nunito-Regular.ttf',
  ];

  // Existing real assets must stay in the manifest so other lookups still work.
  final Map<String, List<Object?>> manifest = <String, List<Object?>>{
    'assets/icon/app_icon.png': const <Object?>[],
    'assets/icon/app_icon.svg': const <Object?>[],
    'packages/lucide_flutter/assets/lucide.ttf': const <Object?>[],
    for (final String a in fontAssets) a: const <Object?>[],
  };
  final ByteData manifestBin =
      const StandardMessageCodec().encodeMessage(manifest)!;

  final TestDefaultBinaryMessenger messenger =
      tester.binding.defaultBinaryMessenger;
  final ByteData robotoData = ByteData.view(robotoBytes.buffer);

  messenger.setMockMessageHandler('flutter/assets', (ByteData? message) async {
    final String? key = const StringCodec().decodeMessage(message);
    if (key == 'AssetManifest.bin') return manifestBin;
    if (fontAssets.contains(key)) return robotoData;
    return null; // Fall through (real bundle handles app_icon/lucide etc.).
  });
  addTearDown(
      () => messenger.setMockMessageHandler('flutter/assets', null));
}

Uint8List _robotoBytes() {
  for (final String path in _candidatePaths()) {
    final File f = File('$path/Roboto-Regular.ttf');
    if (f.existsSync()) return Uint8List.fromList(f.readAsBytesSync());
  }
  return Uint8List(0);
}

List<String> _candidatePaths() {
  final List<String> out = <String>[];
  final String? root = Platform.environment['FLUTTER_ROOT'];
  if (root != null && root.isNotEmpty) {
    out.add('$root/bin/cache/artifacts/material_fonts');
  }
  try {
    final Directory cache =
        File(Platform.resolvedExecutable).parent.parent.parent;
    out.add('${cache.path}/artifacts/material_fonts');
  } catch (_) {}
  return out;
}
