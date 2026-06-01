import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/flow_mode/presentation/dot_row.dart';

import 'visual_golden_helper.dart';

void main() {
  testWidgets('DotRow responsive golden sweep', (tester) async {
    await goldenAtSizes(
      tester,
      name: 'dot_row',
      // DotRow is a self-contained widget (no providers). It draws a rolling
      // 7-day dot strip plus single-letter weekday labels, so the text-scale
      // sweep at a narrow width is the interesting axis for overflow.
      home: Scaffold(
        body: Center(
          child: DotRow(
            activeDays: const {'2026-03-28', '2026-03-27'},
            onDayTap: (_) {},
          ),
        ),
      ),
      // The app builds its ThemeData via google_fonts (Lora/Nunito), which
      // cannot load in a headless golden render. Bypass it with a plain theme
      // backed by the SDK Roboto that flutter_test_config.dart loads, while
      // still giving DotRow a real colorScheme to read (active/today dots).
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB07A3C)),
      ),
      sizes: const {
        'phone': Size(360, 740),
        'narrow': Size(320, 740),
      },
      textScales: const <double>[1.0, 3.0],
    );
  });
}
