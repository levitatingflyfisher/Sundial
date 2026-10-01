import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/flow_mode/presentation/sundial_face.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';

/// The dial's small print ("One sweep = 3h", "Lap 2 ...") was painted at a
/// literal 10 px with no text scaler, so it ignored the reader's text size
/// (batch 1b finding). It now takes the reader's scale, capped at 2x (the
/// WCAG 200%) so it stays inside the dial.
void main() {
  Future<CustomPainter> painterAt(
      WidgetTester tester, double scale, FlowTimerStyle style) async {
    await tester.pumpWidget(MaterialApp(
      builder: (c, w) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: w!),
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 250,
          child: SundialFace(
              elapsed: const Duration(minutes: 40),
              yearTotal: Duration.zero,
              style: style),
        ),
      ),
    ));
    await tester.pump();
    return tester
        .widget<CustomPaint>(find.descendant(
            of: find.byType(SundialFace), matching: find.byType(CustomPaint)))
        .painter!;
  }

  for (final style in FlowTimerStyle.values) {
    testWidgets('${style.name}: the caption follows the reader\'s text size',
        (tester) async {
      final at13 = await painterAt(tester, 1.3, style) as dynamic;
      expect(at13.captionScaler, const TextScaler.linear(1.3));
      final at3 = await painterAt(tester, 3.0, style) as dynamic;
      expect((at3.captionScaler as TextScaler).scale(10), closeTo(20, 1e-9),
          reason: 'capped at 2x so it stays inside the dial');
    });
  }
}
