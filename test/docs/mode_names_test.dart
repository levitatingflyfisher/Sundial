// The two surfaces are called Flow and Rich on screen (the mode pill), but
// README, VISION, AGENTS and docs/ called them Focus and Full (batch 1b
// finding). A reader looking for "Focus" finds nothing in the app. The
// docs use the names the app shows.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the mode pill says Flow and Rich', () {
    final pill = File('lib/shared/widgets/mode_pill.dart').readAsStringSync();
    expect(pill, contains("label: 'Flow'"));
    expect(pill, contains("label: 'Rich'"));
  });

  test('the docs call the modes what the app calls them', () {
    // Any "Focus" or "Full" naming a mode: "Focus mode", "Focus and Rich",
    // "Focus is the default", "(Focus\nand Full)" ...
    final stale = RegExp(r'\b(Focus|Full) mode|\bFocus\b|\(Full\b|\bFull\)|'
        r'\bFull (once|surface)|and Full\b|vs\.? Full\b|\*Full\*');
    final docs = [
      for (final p in ['README.md', 'VISION.md', 'AGENTS.md']) File(p),
      ...Directory('docs')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
        // Local working notes, never committed.
        .where((f) => !f.path.contains('superpowers')),
    ];
    final hits = <String>[];
    for (final f in docs) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (stale.hasMatch(lines[i])) hits.add('${f.path}:${i + 1}');
      }
    }
    expect(hits, isEmpty);
  });
}
