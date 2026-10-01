import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/flow_mode/presentation/sundial_face.dart';

/// The dial paints its own text with TextPainter, which does not inherit the
/// app theme. With no fontFamily it fell back to the platform font instead of
/// the app's bundled Nunito (openhearth_design's package font). Each painted
/// run is measured against the same string laid out in that family: equal
/// widths mean the family resolved to the bundled file.
class _Widths implements Canvas {
  final widths = <double>[];

  @override
  void drawParagraph(ui.Paragraph p, Offset offset) =>
      widths.add(p.longestLine);

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

double _width(String text, double size, FontWeight weight,
    {bool nunito = true}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: nunito ? 'Nunito' : null,
        package: nunito ? 'openhearth_design' : null,
        fontSize: size,
        fontWeight: weight,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  return tp.width;
}

void main() {
  const elapsed = Duration(hours: 1, minutes: 23);
  const max = Duration(hours: 3);
  const caption = 'One sweep = 3h';

  test('the bundled Nunito is loaded in tests (else this file proves nothing)',
      () {
    expect(_width(caption, 10, FontWeight.w600),
        isNot(closeTo(_width(caption, 10, FontWeight.w600, nunito: false),
            0.01)));
  });

  test('gnomon paints its time, ticks and caption in Nunito', () {
    final rec = _Widths();
    const GnomonPainter(
      elapsed: elapsed,
      maxDuration: max,
      sweepColor: Colors.orange,
      trackColor: Colors.grey,
      sunColor: Colors.orange,
      textColor: Colors.black,
    ).paint(rec, const Size(240, 240));
    expect(rec.widths.first, closeTo(_width('15m', 8, FontWeight.w700), 0.01));
    expect(rec.widths[rec.widths.length - 2],
        closeTo(_width('1:23:00', 20, FontWeight.w700), 0.01));
    expect(rec.widths.last, closeTo(_width(caption, 10, FontWeight.w600), 0.01));
  });

  test('arc paints its time and caption in Nunito', () {
    final rec = _Widths();
    const ArcPainter(
      elapsed: elapsed,
      maxDuration: max,
      sweepColor: Colors.orange,
      trackColor: Colors.grey,
      sunColor: Colors.orange,
      textColor: Colors.black,
    ).paint(rec, const Size(240, 240));
    expect(rec.widths.first,
        closeTo(_width('1:23:00', 22, FontWeight.w700), 0.01));
    expect(rec.widths.last, closeTo(_width(caption, 10, FontWeight.w600), 0.01));
  });

  test('dualRing paints its time, year and caption in Nunito', () {
    final rec = _Widths();
    const DualRingPainter(
      elapsed: elapsed,
      maxDuration: max,
      annualGoalHours: 1000,
      yearTotal: Duration(hours: 247),
      sweepColor: Colors.orange,
      trackColor: Colors.grey,
      sunColor: Colors.orange,
      textColor: Colors.black,
    ).paint(rec, const Size(240, 240));
    expect(rec.widths[0], closeTo(_width('1:23:00', 20, FontWeight.w700), 0.01));
    expect(rec.widths[1],
        closeTo(_width('247h / 1000h', 10, FontWeight.w400), 0.01));
    expect(rec.widths[2], closeTo(_width(caption, 10, FontWeight.w600), 0.01));
  });
}
