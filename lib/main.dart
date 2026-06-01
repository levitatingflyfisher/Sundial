// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/router/app_router.dart';
import 'package:sundial/features/timer/data/auto_stop_service.dart';
import 'package:sundial/features/timer/data/timer_notification_service.dart'
    show initTimerNotifications, mediaSessionChannel;
import 'package:sundial/features/timer/domain/timer_state.dart';
import 'package:sundial/features/timer/presentation/timer_notifier.dart';
import 'package:sundial/shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await initTimerNotifications();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SundialApp(),
    ),
  );
}

class SundialApp extends ConsumerStatefulWidget {
  const SundialApp({super.key});

  @override
  ConsumerState<SundialApp> createState() => _SundialAppState();
}

class _SundialAppState extends ConsumerState<SundialApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: () async {
        await _checkAutoStop();
        await _refreshWidget();
      },
    );
    // Attach the lifecycle observer that clears the widget-launch override on
    // app pause. Reading the provider has a side-effect registration.
    ref.read(widgetLaunchLifecycleObserverProvider);
    // Listen for host → Dart "launchSource" calls from MainActivity.kt. When
    // the user taps the home-screen widget, flip into the transient Flow
    // override so AppShell renders FlowScreen regardless of the durable
    // AppMode preference.
    mediaSessionChannel.setMethodCallHandler((call) async {
      if (call.method == 'launchSource') {
        final source = (call.arguments as Map?)?['source'] as String?;
        if (source == 'widget') {
          ref.read(widgetLaunchOverrideProvider.notifier).state = true;
        }
      } else if (call.method == 'timerAction') {
        final args = call.arguments as Map?;
        final action = args?['action'] as String?;
        final notifier = ref.read(timerNotifierProvider.notifier);
        final timerState = ref.read(timerNotifierProvider);
        switch (action) {
          case 'pause':
            if (timerState is TimerRunning) {
              await notifier.pause(fromNative: true);
            }
          case 'resume':
            if (timerState is TimerPaused) {
              await notifier.resume(fromNative: true);
            }
          case 'stop':
            if (timerState is TimerRunning || timerState is TimerPaused) {
              await notifier.stopAndSave(fromNative: true);
            }
        }
      }
      return null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshWidget());
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _refreshWidget() async {
    try {
      final now = DateTime.now();
      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await ref.read(timerNotifierProvider.notifier).refreshWidget(todayKey);
    } catch (_) {}
  }

  Future<void> _checkAutoStop() async {
    final prefs = await ref.read(settingsRepositoryProvider).getUserPrefs();
    if (!prefs.autoStopEnabled) return;

    final sharedPrefs = ref.read(sharedPreferencesProvider);
    final startMs = sharedPrefs.getInt('timer_start_ms');

    if (AutoStopService.shouldTrigger(
      timerStartMs: startMs,
      thresholdHours: prefs.autoStopThresholdHours,
    )) {
      await ref.read(timerNotifierProvider.notifier).buildDraftSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Sundial',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        final inner = child ?? const SizedBox.shrink();
        if (MediaQuery.of(context).size.width <= 760) return inner;
        return ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Center(child: SizedBox(width: 760, child: inner)),
        );
      },
    );
  }
}
