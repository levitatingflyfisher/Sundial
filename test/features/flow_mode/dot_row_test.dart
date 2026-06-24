import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/flow_mode/presentation/dot_row.dart';

void main() {
  testWidgets('DotRow shows 7 dots', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DotRow(
            activeDays: const {'2026-03-28', '2026-03-27'},
            onDayTap: (_) {},
          ),
        ),
      ),
    );
    // 7 dots rendered
    expect(find.byType(GestureDetector), findsNWidgets(7));
  });
}
