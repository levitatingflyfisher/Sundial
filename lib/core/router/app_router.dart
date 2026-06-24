// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/router/app_shell.dart';
import 'package:sundial/features/onboarding/presentation/onboarding_screen.dart';
import 'package:sundial/features/sessions/presentation/history_screen.dart';
import 'package:sundial/features/sessions/presentation/manual_entry_sheet.dart';
import 'package:sundial/features/sessions/presentation/session_edit_sheet.dart';
import 'package:sundial/features/export/presentation/export_screen.dart';
import 'package:sundial/features/profiles/presentation/profiles_screen.dart';
import 'package:sundial/features/settings/presentation/settings_screen.dart';
import 'package:sundial/features/stats/presentation/stats_screen.dart';
import 'package:sundial/features/timer/presentation/timer_screen.dart';

part 'app_router.g.dart';

CustomTransitionPage<T> _fadePage<T>({
  required LocalKey key,
  required Widget child,
  Duration duration = const Duration(milliseconds: 400),
}) =>
    CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );

CustomTransitionPage<T> _slideUpPage<T>({
  required LocalKey key,
  required Widget child,
}) =>
    CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );

@riverpod
GoRouter appRouter(Ref ref) {
  final db = ref.watch(appDatabaseProvider);

  return GoRouter(
    initialLocation: '/timer',
    redirect: (context, state) async {
      if (state.matchedLocation == '/onboarding') return null;
      final rawPrefs = await db.select(db.userPrefs).get();
      if (rawPrefs.isEmpty) return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          duration: const Duration(milliseconds: 500),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/timer',
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const TimerScreen(),
            ),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const HistoryScreen(),
            ),
          ),
          GoRoute(
            path: '/stats',
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const StatsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/settings/profiles',
        pageBuilder: (context, state) => _slideUpPage(
          key: state.pageKey,
          child: const ProfilesScreen(),
        ),
      ),
      GoRoute(
        path: '/export',
        pageBuilder: (context, state) => _slideUpPage(
          key: state.pageKey,
          child: const ExportScreen(),
        ),
      ),
      GoRoute(
        path: '/sessions/add',
        pageBuilder: (context, state) => _slideUpPage(
          key: state.pageKey,
          child: ManualEntrySheet(initialDate: state.extra as DateTime?),
        ),
      ),
      GoRoute(
        path: '/sessions/:id/edit',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final session = state.extra;
          return _slideUpPage(
            key: state.pageKey,
            child: SessionEditSheet(sessionId: id, initialSession: session),
          );
        },
      ),
    ],
  );
}
