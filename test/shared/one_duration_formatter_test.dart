import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/export/data/pdf_export_impl.dart';
import 'package:sundial/features/flow_mode/presentation/flow_screen.dart';
import 'package:sundial/features/stats/presentation/cumulative_chart.dart';
import 'package:sundial/shared/extensions/duration_ext.dart';

/// dmmt-01: one 30-minute session printed as 0h (Flow), 30m (Timer, tiles),
/// 1h (chart header) and 0h (PDF), because three local formatters bypassed
/// toHoursLabel(). Every duration a person reads now goes through it.
void main() {
  test('toHoursLabel: under a minute reads in seconds, zero reads 0m', () {
    expect(const Duration(seconds: 45).toHoursLabel(), '45s');
    expect(Duration.zero.toHoursLabel(), '0m');
  });

  Session session(int secs) {
    final now = DateTime.now();
    final day = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return Session(
      id: 's',
      startTime: now.millisecondsSinceEpoch,
      endTime: now.millisecondsSinceEpoch + secs * 1000,
      durationSecs: secs,
      dateDay: day,
      createdAt: 0,
      updatedAt: 0,
    );
  }

  test('PDF cover total is not truncated to whole hours', () {
    expect(PdfExporter.totalLoggedLine([session(1800)]), 'Total logged: 30m');
    expect(PdfExporter.durationCell(session(45)), '45s');
  });

  group('screens', () {
    late AppDatabase db;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase(NativeDatabase.memory());
      await db.into(db.sessions).insert(session(1800)
          .toCompanion(true)
          .copyWith(profileId: const Value(null)));
    });

    Future<void> pump(WidgetTester tester, Widget child) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.binding.setSurfaceSize(const Size(600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      ));
      await tester.pumpAndSettle();
    }

    Future<void> drain(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await db.close();
    }

    testWidgets('all-time chart header says 30m total, not 1h',
        (tester) async {
      await pump(tester, const CumulativeChart());
      expect(find.text('30m total'), findsOneWidget);
      await drain(tester);
    });

    testWidgets('Flow year line says 30m, not 0h', (tester) async {
      await pump(tester, const FlowScreen());
      expect(find.textContaining('30m / 1000h this year'), findsOneWidget);
      expect(find.textContaining('0h / 1000h'), findsNothing);
      await drain(tester);
    });
  });
}
