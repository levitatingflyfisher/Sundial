// lib/core/router/app_shell.dart
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/features/flow_mode/presentation/flow_screen.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';
import 'package:sundial/shared/theme/app_colors.dart';
import 'package:sundial/shared/widgets/mode_pill.dart';
import 'package:sundial/shared/widgets/theme_toggle.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Heal stale active-profile selections. If the saved profile ID no longer
    // exists (deleted elsewhere, bad restore, etc.) fall back to Everyone so
    // the rest of the UI doesn't silently filter to an empty set.
    ref.listen(profilesListProvider, (_, next) {
      final profiles = next.valueOrNull;
      if (profiles == null) return;
      final activeId = ref.read(activeProfileIdProvider);
      if (activeId == kEveryoneProfileId) return;
      if (profiles.any((p) => p.id == activeId)) return;
      ref.read(activeProfileIdProvider.notifier).select(kEveryoneProfileId);
    });

    ref.listen(newlyEarnedBadgesProvider, (_, badges) {
      if (badges.isEmpty) return;
      _confetti.play();
      final topBadge = badges.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            // Badge thresholds are all-time totals, so the line says so
            // (it used to claim "this year", badass-02).
            '${topBadge.thresholdHours}h milestone: '
            '${topBadge.thresholdHours} hours outside, all time',
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          ref.read(newlyEarnedBadgesProvider.notifier).state = const [];
        }
      });
    });

    // Widget-tap launches force Flow mode until the next pause — a
    // transient glance shouldn't land users inside the tabbed Rich shell,
    // regardless of their durable preference.
    final widgetOverride = ref.watch(widgetLaunchOverrideProvider);
    final modeAsync = ref.watch(appModeProvider);
    final content = widgetOverride
        ? const FlowScreen()
        : modeAsync.when(
            data: (mode) => mode == AppMode.flow
                ? _FlowShell(child: widget.child)
                : _RichShell(child: widget.child),
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const FlowScreen(),
          );

    return Stack(
      children: [
        content,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              AppColors.sage500,
              AppColors.sage600,
              AppColors.sunGold,
              AppColors.linen200,
              Colors.white,
            ],
          ),
        ),
      ],
    );
  }
}

/// Flow mode: the timer is the whole app, but History, Stats and Settings
/// stay reachable from it without switching mode (ruling Q-D1). They open
/// as a plain page with a way back to the timer.
class _FlowShell extends StatelessWidget {
  const _FlowShell({required this.child});
  final Widget child;

  static const _titles = {
    '/history': 'History',
    '/stats': 'Stats',
    '/settings': 'Settings',
  };

  @override
  Widget build(BuildContext context) {
    final title = _titles[GoRouterState.of(context).matchedLocation];
    if (title == null) return const FlowScreen();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          tooltip: 'Back to the timer',
          onPressed: () => context.go('/timer'),
        ),
        title: Text(title),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: ThemeToggle(),
          ),
        ],
      ),
      body: OhPage(padding: EdgeInsets.zero, child: child),
    );
  }
}

class _RichShell extends StatelessWidget {
  const _RichShell({required this.child});
  final Widget child;

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return switch (location) {
      '/history' => 1,
      '/stats' => 2,
      '/settings' => 3,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sundial'),
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: ThemeToggle(),
          ),
        ],
      ),
      // Cap and centre the tab content on tablets and in the browser; the
      // app bar and bottom bar stay full width.
      body: OhPage(padding: EdgeInsets.zero, child: child),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: ModePill(),
          ),
          NavigationBar(
            selectedIndex: _selectedIndex(context),
            onDestinationSelected: (i) {
              const routes = ['/timer', '/history', '/stats', '/settings'];
              context.go(routes[i]);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(LucideIcons.timer),
                label: 'Timer',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.history),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.barChart2),
                label: 'Stats',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
