import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/sessions/presentation/history_screen.dart';

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('HistoryScreen shows empty state when no sessions', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((_) => AppDatabase(NativeDatabase.memory())),
      ],
      child: const MaterialApp(home: HistoryScreen()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('No sessions'), findsOneWidget);
    // Drain any pending Drift stream timers before teardown.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
