import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/sessions/presentation/session_edit_sheet.dart';

Session _makeSession() => Session(
  id: 'test-id',
  startTime: DateTime(2026, 3, 28, 9).millisecondsSinceEpoch,
  endTime: DateTime(2026, 3, 28, 11, 30).millisecondsSinceEpoch,
  durationSecs: 9000,
  notes: null,
  dateDay: '2026-03-28',
  locationLabel: null, lat: null, lng: null,
  createdAt: 0, updatedAt: 0,
);

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('SessionEditSheet shows current duration', (tester) async {
    final session = _makeSession();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((_) => AppDatabase(NativeDatabase.memory())),
      ],
      child: MaterialApp(
        home: Scaffold(body: SessionEditSheet(sessionId: session.id, initialSession: session)),
      ),
    ));
    await tester.pump();
    // 9000s = 2h 30m — spinner pads to 2 digits
    expect(find.text('02'), findsWidgets);
    expect(find.text('30'), findsWidgets);
  });

  testWidgets('SessionEditSheet has Save button', (tester) async {
    final session = _makeSession();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((_) => AppDatabase(NativeDatabase.memory())),
      ],
      child: MaterialApp(
        home: Scaffold(body: SessionEditSheet(sessionId: session.id, initialSession: session)),
      ),
    ));
    await tester.pump();
    expect(find.text('Save'), findsOneWidget);
  });
}
