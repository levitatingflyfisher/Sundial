import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';
import 'package:sundial/features/timer/domain/timer_state.dart';
import 'package:sundial/features/timer/presentation/timer_notifier.dart';
import 'package:sundial/shared/widgets/mode_pill.dart';
import 'package:sundial/shared/widgets/profile_chip_row.dart';
import 'package:sundial/shared/widgets/theme_pill.dart';
import 'dot_row.dart';
import 'sundial_face.dart';

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class FlowScreen extends ConsumerWidget {
  const FlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerNotifierProvider);
    final notifier = ref.read(timerNotifierProvider.notifier);
    final prefsAsync = ref.watch(userPrefsProvider);
    final prefs = prefsAsync.valueOrNull;

    final annualGoal = prefs?.annualGoalHours ?? 1000;
    final style = prefs?.flowTimerStyle ?? FlowTimerStyle.gnomon;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: ThemePill(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const ProfileChipRow(),
            const SizedBox(height: 8),
            _DotRowSection(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AspectRatio(
                aspectRatio: 240 / 200,
                child: SundialFace(
                  elapsed: notifier.elapsed,
                  style: style,
                  isRunning: timerState is TimerRunning,
                  annualGoalHours: annualGoal,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _FlowControls(state: timerState, notifier: notifier),
            const SizedBox(height: 16),
            _YearStatus(annualGoal: annualGoal),
            const SizedBox(height: 24),
            const ModePill(),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _DotRowSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DotRowSection> createState() => _DotRowSectionState();
}

class _DotRowSectionState extends ConsumerState<_DotRowSection> {
  late Stream<Set<String>> _activeDaysStream;

  @override
  void initState() {
    super.initState();
    _activeDaysStream = _buildStream();
  }

  Stream<Set<String>> _buildStream() {
    final repo = ref.read(sessionsRepositoryProvider);
    final now = DateTime.now();
    return Stream.fromFuture(Future.wait(
      List.generate(7, (i) {
        final day = now.subtract(Duration(days: 6 - i));
        final key = _dateKey(day);
        return repo
            .watchSecondsForDay(key)
            .first
            .then((secs) => secs > 0 ? key : null);
      }),
    )).map((results) => results.whereType<String>().toSet());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Set<String>>(
      stream: _activeDaysStream,
      builder: (context, snap) => DotRow(
        activeDays: snap.data ?? const {},
        onDayTap: (_) {},
      ),
    );
  }
}

class _FlowControls extends StatelessWidget {
  const _FlowControls({required this.state, required this.notifier});
  final TimerState state;
  final TimerNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      TimerIdle() => FilledButton.icon(
          onPressed: notifier.start,
          icon: const Icon(LucideIcons.play, size: 24),
          label: const Text('START', style: TextStyle(fontSize: 18)),
          style: FilledButton.styleFrom(minimumSize: const Size(160, 56)),
        ),
      TimerRunning() => FilledButton.icon(
          onPressed: () async {
            final session = await notifier.stopAndSave();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Session saved'),
                action: SnackBarAction(
                  label: 'Add notes',
                  onPressed: () => context.push(
                    '/sessions/${session.id}/edit',
                    extra: session,
                  ),
                ),
              ));
            }
          },
          icon: const Icon(LucideIcons.square, size: 24),
          label: const Text('STOP', style: TextStyle(fontSize: 18)),
          style: FilledButton.styleFrom(
            minimumSize: const Size(160, 56),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      TimerPaused() => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: notifier.resume,
              child: const Text('RESUME'),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: () async {
                final session = await notifier.stopAndSave();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Session saved'),
                    action: SnackBarAction(
                      label: 'Add notes',
                      onPressed: () => context.push(
                        '/sessions/${session.id}/edit',
                        extra: session,
                      ),
                    ),
                  ));
                }
              },
              child: const Text('STOP'),
            ),
          ],
        ),
      TimerStopped(:final session) => Column(
          children: [
            FilledButton(
              onPressed: () => context.push(
                '/sessions/${session.id}/edit',
                extra: session,
              ),
              child: const Text('Review & Save'),
            ),
            TextButton(
              onPressed: notifier.discard,
              child: const Text('Discard'),
            ),
          ],
        ),
    };
  }
}

class _YearStatus extends ConsumerWidget {
  const _YearStatus({required this.annualGoal});
  final int annualGoal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = DateTime.now().year.toString();
    final secsStream =
        ref.watch(sessionsRepositoryProvider).watchSecondsForYear(year);

    return StreamBuilder<int>(
      stream: secsStream,
      builder: (context, snap) {
        final totalHours = (snap.data ?? 0) ~/ 3600;
        return Text(
          '${totalHours}h / ${annualGoal}h this year',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        );
      },
    );
  }
}
