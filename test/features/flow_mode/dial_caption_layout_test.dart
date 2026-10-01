import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/flow_mode/presentation/sundial_face.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';

/// Where the dial's small print lands as the reader's text grows (ruling
/// Q-S1).
///
/// The caption ("One sweep = 3h") used to wrap at large text and was centred
/// on its anchor, so it grew upward too: over the Arc's time, over the Dual
/// Ring's year total and across the Gnomon's base line. Now it stays on one
/// line, hangs from where its 1x line sits, and grows only as far as the
/// free space at that height allows (never below 1x).
class _TextRecorder implements Canvas {
  final rects = <Rect>[];
  final lines = <int>[];

  @override
  void drawParagraph(ui.Paragraph p, Offset offset) {
    // Text laid out to a finite width is centred inside it; unbounded text
    // starts at the offset.
    final inset = p.width.isFinite ? (p.width - p.longestLine) / 2 : 0.0;
    rects.add(
        Rect.fromLTWH(offset.dx + inset, offset.dy, p.longestLine, p.height));
    lines.add(p.computeLineMetrics().length);
  }

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

const _elapsed = Duration(hours: 1, minutes: 23);
const _max = Duration(hours: 3);

CustomPainter _face(FlowTimerStyle style, TextScaler scaler) =>
    switch (style) {
      FlowTimerStyle.gnomon => GnomonPainter(
          elapsed: _elapsed,
          maxDuration: _max,
          sweepColor: Colors.orange,
          trackColor: Colors.grey,
          sunColor: Colors.orange,
          textColor: Colors.black,
          captionScaler: scaler,
        ),
      FlowTimerStyle.arc => ArcPainter(
          elapsed: _elapsed,
          maxDuration: _max,
          sweepColor: Colors.orange,
          trackColor: Colors.grey,
          sunColor: Colors.orange,
          textColor: Colors.black,
          captionScaler: scaler,
        ),
      FlowTimerStyle.dualRing => DualRingPainter(
          elapsed: _elapsed,
          maxDuration: _max,
          annualGoalHours: 1000,
          yearTotal: const Duration(hours: 247),
          sweepColor: Colors.orange,
          trackColor: Colors.grey,
          sunColor: Colors.orange,
          textColor: Colors.black,
          captionScaler: scaler,
        ),
    };

_TextRecorder _paint(FlowTimerStyle style, Size size, double scale) {
  final rec = _TextRecorder();
  _face(style, TextScaler.linear(scale)).paint(rec, size);
  return rec;
}

void _expectApart(List<Rect> rects) {
  for (var i = 0; i < rects.length; i++) {
    for (var j = i + 1; j < rects.length; j++) {
      final o = rects[i].intersect(rects[j]);
      expect(o.width > 0 && o.height > 0, isFalse,
          reason: 'text ${rects[i]} overlaps text ${rects[j]}');
    }
  }
}

/// The open space a caption may use: inside the ring's stroke for the round
/// faces, below the base line and inside the box for the Gnomon.
void _expectInFreeSpace(FlowTimerStyle style, Size size, Rect caption) {
  switch (style) {
    case FlowTimerStyle.gnomon:
      expect(caption.top, greaterThanOrEqualTo(size.height * 0.82),
          reason: 'the caption crosses the dial\'s base line');
      expect(caption.bottom, lessThanOrEqualTo(size.height),
          reason: 'the caption runs out of the dial\'s box');
    case FlowTimerStyle.arc || FlowTimerStyle.dualRing:
      final c = size.center(Offset.zero);
      final r = style == FlowTimerStyle.arc
          ? size.width * 0.42 - 5
          : size.width * 0.32 - 5;
      for (final corner in [caption.bottomLeft, caption.bottomRight]) {
        expect((corner - c).distance, lessThanOrEqualTo(r),
            reason: 'the caption crosses the ring');
      }
  }
}

void main() {
  // The sweep's boxes (240) and a roomy one; text from 1x to past the cap.
  const sizes = [Size(240, 240), Size(400, 400)];
  const scales = [1.0, 1.3, 2.0, 3.0];

  for (final style in FlowTimerStyle.values) {
    for (final size in sizes) {
      for (final scale in scales) {
        testWidgets(
            '${style.name} ${size.width.toInt()}px at ${scale}x: one line, '
            'in free space, clear of the other text', (tester) async {
          final rec = _paint(style, size, scale);
          final caption = rec.rects.last;
          expect(rec.lines.last, 1, reason: 'the caption wrapped');
          _expectApart(rec.rects);
          _expectInFreeSpace(style, size, caption);
        });
      }
    }

    testWidgets('${style.name}: a 1x caption sits where it always did',
        (tester) async {
      // Its own height at 1x, centred on the painter's anchor.
      final one = _paint(style, const Size(240, 240), 1.0).rects.last;
      final grown = _paint(style, const Size(240, 240), 2.0).rects.last;
      expect(grown.top, closeTo(one.top, 1e-6),
          reason: 'the caption hangs from its 1x top');
    });

    testWidgets('${style.name}: it never shrinks below 1x, and grows when '
        'there is room', (tester) async {
      final one = _paint(style, const Size(400, 400), 1.0).rects.last;
      final two = _paint(style, const Size(400, 400), 2.0).rects.last;
      expect(two.height, closeTo(one.height * 2, one.height * 0.1),
          reason: 'a roomy dial shows the full 2x');
      for (final scale in [1.3, 2.0, 3.0]) {
        final small = _paint(style, const Size(240, 240), scale).rects.last;
        expect(small.height, greaterThanOrEqualTo(one.height - 1e-6));
        expect(small.height,
            lessThanOrEqualTo(math.min(scale, 2.0) * one.height + 1e-6));
      }
    });
  }
}
