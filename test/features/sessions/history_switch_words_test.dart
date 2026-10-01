import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/sessions/presentation/history_screen.dart';
import 'package:sundial/shared/theme/app_theme.dart';

/// At 320 dp and 2x-3x text the History view switch broke "Calendar"
/// mid-word (batch 1b finding). Each segment's word stays whole.
void main() {
  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets('Calendar | List stay whole words at 320 dp x $scale',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (c, w) => MediaQuery(
              data: MediaQuery.of(c)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: w!),
          home: const HistoryScreen(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      for (final w in ['Calendar', 'List']) {
        final p = tester.renderObject<RenderParagraph>(find.text(w));
        final tops = p
            .getBoxesForSelection(
                TextSelection(baseOffset: 0, extentOffset: w.length))
            .map((b) => b.top.round())
            .toSet();
        expect(tops, hasLength(1), reason: '"$w" breaks at $scale');
        expect(p.getMaxIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(p.size.width + 0.5),
            reason: '"$w" is cut at $scale');
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
