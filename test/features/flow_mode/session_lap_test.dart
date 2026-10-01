import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/flow_mode/presentation/sundial_face.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';

/// visual-04 / ruling Q-D5: the dial's full arc was an undeclared 3 hours,
/// so from 3h to 6h the arc did not move (Lie Factor 0). The arc stays a
/// session gauge with its scale stated on the face, and past 3h it wraps
/// for a second lap that the face names.
void main() {
  const lap = Duration(hours: 3);

  group('sessionLap', () {
    test('within the first lap, progress is the share of 3h', () {
      expect(sessionLap(Duration.zero, lap), (progress: 0.0, lap: 1));
      expect(sessionLap(const Duration(minutes: 90), lap),
          (progress: 0.5, lap: 1));
    });

    test('exactly 3h is a full first lap, not an empty second', () {
      expect(sessionLap(lap, lap), (progress: 1.0, lap: 1));
    });

    test('past 3h the arc moves again, on lap 2', () {
      final r = sessionLap(const Duration(hours: 4, minutes: 30), lap);
      expect(r.lap, 2);
      expect(r.progress, closeTo(0.5, 1e-9));
    });

    test('a long day keeps counting laps', () {
      final r = sessionLap(const Duration(hours: 7), lap);
      expect(r.lap, 3);
      expect(r.progress, closeTo(1 / 3, 1e-9));
    });
  });

  Future<String> labelFor(WidgetTester tester, Duration elapsed,
      FlowTimerStyle style) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 250,
          child: SundialFace(
            elapsed: elapsed,
            yearTotal: Duration.zero,
            style: style,
          ),
        ),
      ),
    ));
    return tester
        .getSemantics(find.byType(SundialFace))
        .getSemanticsData()
        .label;
  }

  for (final style in FlowTimerStyle.values) {
    testWidgets('${style.name}: the face states its scale, and the lap past 3h',
        (tester) async {
      final handle = tester.ensureSemantics();
      final early = await labelFor(tester, const Duration(hours: 1), style);
      expect(early, contains('one sweep of the dial is 3 hours'));
      expect(early, isNot(contains('lap')));

      final late = await labelFor(
          tester, const Duration(hours: 4, minutes: 30), style);
      expect(late, contains('lap 2'));
      handle.dispose();
    });
  }
}
