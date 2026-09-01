// lib/features/timer/presentation/unsaved_session_panel.dart
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/timer/presentation/timer_notifier.dart';
import 'package:sundial/shared/extensions/duration_ext.dart';
import 'package:sundial/shared/theme/app_spacing.dart';

/// The Undo offer for a discarded draft. It outlives the panel (which
/// disappears the moment the timer goes idle), so it lives in a provider
/// and each timer screen shows it in an [OhUndoBar].
final timerUndoControllerProvider = Provider<OhUndoController>((ref) {
  final controller = OhUndoController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// Shown when the timer holds a session that is not saved: STOP saves at
/// once, so in practice this is an auto-stop whose save failed (the draft is
/// kept rather than lost; see TimerNotifier.confirmSession). It says so, reads
/// the session back, and offers Save (retry), Edit first, and Discard with an
/// Undo that never times out (fleet delete ruling). One widget for Timer and
/// Flow, replacing two drifting copies of an unexplained "Review & Save".
class UnsavedSessionPanel extends ConsumerWidget {
  const UnsavedSessionPanel({super.key, required this.session});
  final Session session;

  static final _dayFmt = DateFormat('EEE, MMM d');

  String _readBack() {
    final dur = Duration(seconds: session.durationSecs).toHoursLabel();
    final start = DateTime.fromMillisecondsSinceEpoch(session.startTime);
    final now = clock.now();
    final sameDay = start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
    return '$dur · ${sameDay ? 'today' : _dayFmt.format(start)}';
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final result =
        await ref.read(timerNotifierProvider.notifier).confirmSession(session);
    if (!context.mounted) return;
    result.fold(
      (failure) {
        debugPrint("Couldn't save the session: ${failure.message}");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Couldn’t save the session. Please try again.'),
        ));
      },
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${_readBack()}')),
      ),
    );
  }

  void _discard(WidgetRef ref) {
    final notifier = ref.read(timerNotifierProvider.notifier);
    notifier.discard();
    ref.read(timerUndoControllerProvider).show(
          message: 'Discarded ${_readBack()}',
          onUndo: () async => notifier.restoreDiscarded(session),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'This session isn’t saved yet',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(_readBack(), style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            FilledButton(
              onPressed: () => _save(context, ref),
              child: const Text('Save session'),
            ),
            OutlinedButton(
              onPressed: () =>
                  context.push('/sessions/${session.id}/edit', extra: session),
              child: const Text('Edit first'),
            ),
            TextButton(
              onPressed: () => _discard(ref),
              child: const Text('Discard'),
            ),
          ],
        ),
      ],
    );
  }
}
