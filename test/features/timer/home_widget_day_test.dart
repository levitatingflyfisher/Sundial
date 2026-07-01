// The home-screen widget has exactly ONE slot: 'today_hours'. Callers of
// refreshWidget pass the day a session changed on — history edits, manual
// entries up to 90 days back, cross-midnight stops — and the widget must
// NOT render that historical day's total as if it were today's.
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/timer/presentation/timer_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      "refreshWidget for a historical day writes TODAY's total into the "
      "widget's today_hours slot, not the historical day's", () async {
    String? capturedTodayHours;
    const channel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      // Handle BOTH methods — a handler that only knows saveWidgetData
      // throws MissingPluginException on updateWidget, which the notifier's
      // catch swallows, masking the assertion.
      if (call.method == 'saveWidgetData') {
        final args = call.arguments as Map;
        if (args['id'] == 'today_hours') {
          capturedTodayHours = args['data'] as String?;
        }
        return true;
      }
      return null; // updateWidget and friends
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWith((_) => db),
    ]);
    addTearDown(container.dispose);

    // Seed a 2h session on a day far in the past; today has NO sessions.
    final past = DateTime(2000, 1, 1, 9);
    await db.into(db.sessions).insert(Session(
          id: 'past-session',
          startTime: past.millisecondsSinceEpoch,
          endTime: past.add(const Duration(hours: 2)).millisecondsSinceEpoch,
          durationSecs: 7200,
          notes: null,
          dateDay: '2000-01-01',
          profileId: null,
          locationLabel: null,
          lat: null,
          lng: null,
          createdAt: past.millisecondsSinceEpoch,
          updatedAt: past.millisecondsSinceEpoch,
        ));

    final notifier = container.read(timerNotifierProvider.notifier);
    await notifier.refreshWidget('2000-01-01');

    expect(capturedTodayHours, isNotNull,
        reason: 'the widget refresh must have written the today_hours slot');
    expect(capturedTodayHours, '0m',
        reason: "the today_hours slot must show TODAY's total (empty → 0m), "
            "not the historical day's 2h");
  });
}
