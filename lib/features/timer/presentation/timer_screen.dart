// lib/features/timer/presentation/timer_screen.dart
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/features/timer/domain/timer_state.dart';
import 'package:sundial/features/timer/presentation/timer_notifier.dart';
import 'package:sundial/shared/extensions/duration_ext.dart';
import 'package:sundial/shared/theme/app_spacing.dart';
import 'package:sundial/shared/theme/app_text_styles.dart';
import 'package:sundial/shared/widgets/profile_chip_row.dart';

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerNotifierProvider);
    final notifier = ref.read(timerNotifierProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const ProfileChipRow(),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                // Scroll the centered timer block so it stays centered when it
                // fits but doesn't overflow at large accessibility text scales.
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TimerDisplay(
                                state: timerState, notifier: notifier),
                            const SizedBox(height: AppSpacing.xl),
                            _TimerControls(
                                state: timerState, notifier: notifier),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const _StatsRow(),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  const _TimerDisplay({required this.state, required this.notifier});
  final TimerState state;
  final TimerNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final elapsed = notifier.elapsed;
    return Column(
      children: [
        Text(
          elapsed.toHhMm(),
          style: AppTextStyles.timerDisplay.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (state is TimerRunning)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Running since ${_formatStart((state as TimerRunning).startTime)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  String _formatStart(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h % 12 == 0 ? 12 : h % 12;
    return '$displayH:$m $period';
  }
}

class _TimerControls extends StatelessWidget {
  const _TimerControls({required this.state, required this.notifier});
  final TimerState state;
  final TimerNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      TimerIdle() => _buildStart(context),
      TimerRunning() => _buildRunning(context),
      TimerPaused() => _buildPaused(context),
      TimerStopped(:final session) => _buildStopped(context, session),
    };
  }

  Widget _buildStart(BuildContext context) => FilledButton.icon(
    onPressed: notifier.start,
    icon: const Icon(LucideIcons.play),
    label: const Text('START'),
    style: FilledButton.styleFrom(minimumSize: const Size(160, 52)),
  );

  Widget _buildRunning(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      OutlinedButton(
        onPressed: notifier.pause,
        child: const Text('PAUSE'),
      ),
      const SizedBox(width: AppSpacing.md),
      FilledButton(
        onPressed: () async {
          final session = await notifier.stopAndSave();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Session saved'),
              action: SnackBarAction(
                label: 'Add notes',
                onPressed: () =>
                    context.push('/sessions/${session.id}/edit', extra: session),
              ),
            ));
          }
        },
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
        child: const Text('STOP'),
      ),
    ],
  );

  Widget _buildPaused(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      FilledButton.icon(
        onPressed: notifier.resume,
        icon: const Icon(LucideIcons.play),
        label: const Text('RESUME'),
      ),
      const SizedBox(width: AppSpacing.md),
      OutlinedButton(
        onPressed: () async {
          final session = await notifier.stopAndSave();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Session saved'),
              action: SnackBarAction(
                label: 'Add notes',
                onPressed: () =>
                    context.push('/sessions/${session.id}/edit', extra: session),
              ),
            ));
          }
        },
        child: const Text('STOP'),
      ),
    ],
  );

  Widget _buildStopped(BuildContext context, session) => Column(
    children: [
      Text(
        'Session ready to save',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: AppSpacing.md),
      FilledButton(
        onPressed: () =>
            context.push('/sessions/${session.id}/edit', extra: session),
        child: const Text('Review & Save'),
      ),
      TextButton(
        onPressed: notifier.discard,
        child: const Text('Discard'),
      ),
    ],
  );
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // clock.now() (not DateTime.now()) so tests can pin which day/year the
    // Today / This Year streams aggregate — same class as StatsScreen's keys.
    final now = clock.now();
    final repo = ref.watch(sessionsRepositoryProvider);
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final prefsAsync = ref.watch(userPrefsProvider);
    final annualGoal = prefsAsync.valueOrNull?.annualGoalHours ?? 1000;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: _StatBox(
            label: 'Today',
            valueStream: repo.watchSecondsForDay(todayKey),
          ),
        ),
        Expanded(
          child: _StatBox(
            label: 'This Year',
            valueStream: repo.watchSecondsForYear(now.year.toString()),
            goalHours: annualGoal,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.valueStream,
    this.goalHours,
  });
  final String label;
  final Stream<int> valueStream;
  final int? goalHours;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: valueStream,
      builder: (context, snap) {
        final secs = snap.data ?? 0;
        final dur = Duration(seconds: secs);
        return Column(
          children: [
            Text(
              dur.toHoursLabel(),
              textAlign: TextAlign.center,
              style: AppTextStyles.statValue.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (goalHours != null)
              Text(
                'of ${goalHours}h goal',
                textAlign: TextAlign.center,
                style: AppTextStyles.statLabel.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.statLabel.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}
