import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/flow_mode/presentation/sundial_face.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('SundialFace golden tests', () {
    testWidgets('Gnomon idle', (tester) async {
      await tester.pumpWidget(_wrap(const SundialFace(
        elapsed: Duration.zero,
        style: FlowTimerStyle.gnomon,
      )));
      await expectLater(
        find.byType(SundialFace),
        matchesGoldenFile('goldens/sundial_gnomon_idle.png'),
      );
    });

    testWidgets('Gnomon running 1h23m', (tester) async {
      await tester.pumpWidget(_wrap(const SundialFace(
        elapsed: Duration(hours: 1, minutes: 23),
        style: FlowTimerStyle.gnomon,
        isRunning: true,
      )));
      await expectLater(
        find.byType(SundialFace),
        matchesGoldenFile('goldens/sundial_gnomon_running.png'),
      );
    });

    testWidgets('Arc running 1h23m', (tester) async {
      await tester.pumpWidget(_wrap(const SundialFace(
        elapsed: Duration(hours: 1, minutes: 23),
        style: FlowTimerStyle.arc,
        isRunning: true,
      )));
      await expectLater(
        find.byType(SundialFace),
        matchesGoldenFile('goldens/sundial_arc_running.png'),
      );
    });

    testWidgets('DualRing running with year progress', (tester) async {
      await tester.pumpWidget(_wrap(const SundialFace(
        elapsed: Duration(hours: 1, minutes: 23),
        style: FlowTimerStyle.dualRing,
        isRunning: true,
        yearTotalHours: 247,
        annualGoalHours: 1000,
      )));
      await expectLater(
        find.byType(SundialFace),
        matchesGoldenFile('goldens/sundial_dualring_running.png'),
      );
    });
  });
}
