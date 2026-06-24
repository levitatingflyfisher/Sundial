import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/flow_mode/presentation/sundial_face.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';

import 'visual_golden_helper.dart';

/// Responsive + text-scale sweep for [SundialFace].
///
/// This is the parametric companion to the hand-coded state variants under
/// `test/features/flow_mode/sundial_face_golden_test.dart` (which pin the four
/// timer styles at fixed sizes). Those committed goldens are intentionally
/// left untouched — this file instead exercises the *layout* axis: how the
/// face's CustomPaint scales across phone/narrow widths and accessibility
/// text scales. The painter sizes everything off the box width, so a narrow
/// box at large text scale is the case most likely to clip the center label.
void main() {
  testWidgets('SundialFace dualRing responsive golden sweep', (tester) async {
    await goldenAtSizes(
      tester,
      name: 'sundial_face_dualring',
      // SundialFace fills its box (Size.infinite), so bound it to a square
      // and let the sweep vary the available width. dualRing carries the most
      // on-canvas text (session time + "247h / 1000h"), so it's the richest
      // overflow target.
      home: const Scaffold(
        body: Center(
          child: SizedBox(
            width: 240,
            height: 240,
            child: SundialFace(
              elapsed: Duration(hours: 1, minutes: 23),
              sessionMax: Duration(hours: 3),
              style: FlowTimerStyle.dualRing,
              isRunning: false,
              annualGoalHours: 1000,
              yearTotalHours: 247,
            ),
          ),
        ),
      ),
      // SundialFace draws its own text via TextPainter (no google_fonts), so a
      // plain Roboto-backed Material3 theme is all the colorScheme it reads.
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      sizes: const {
        'phone': Size(360, 800),
        'narrow': Size(320, 800),
      },
      textScales: const <double>[1.0, 3.0],
    );
  });

  testWidgets('SundialFace gnomon responsive golden sweep', (tester) async {
    await goldenAtSizes(
      tester,
      name: 'sundial_face_gnomon',
      home: const Scaffold(
        body: Center(
          child: SizedBox(
            width: 240,
            height: 240,
            child: SundialFace(
              elapsed: Duration(hours: 1, minutes: 23),
              sessionMax: Duration(hours: 3),
              style: FlowTimerStyle.gnomon,
              isRunning: false,
            ),
          ),
        ),
      ),
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      sizes: const {
        'phone': Size(360, 800),
        'narrow': Size(320, 800),
      },
      textScales: const <double>[1.0, 3.0],
    );
  });
}
