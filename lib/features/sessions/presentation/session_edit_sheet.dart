// lib/features/sessions/presentation/session_edit_sheet.dart
import 'package:fpdart/fpdart.dart';
import 'package:sundial/core/error/failures.dart';
import 'package:drift/drift.dart' hide Table, Column;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/sessions/presentation/session_undo.dart';
import 'package:sundial/features/timer/domain/timer_state.dart';
import 'package:sundial/features/timer/presentation/timer_notifier.dart';
import 'package:sundial/shared/extensions/duration_ext.dart';
import 'package:sundial/shared/theme/app_spacing.dart';

class SessionEditSheet extends ConsumerStatefulWidget {
  const SessionEditSheet({
    super.key,
    required this.sessionId,
    this.initialSession,
  });
  final String sessionId;
  final Object? initialSession;

  @override
  ConsumerState<SessionEditSheet> createState() => _SessionEditSheetState();

  /// Builds the [Session] to persist from the editor's fields. Extracted so the
  /// date/time consistency can be unit-tested without driving the sheet UI.
  @visibleForTesting
  static Session buildSessionForSave({
    required Session? existing,
    required String sessionId,
    required DateTime date,
    required int durationSecs,
    required String notes,
    required int nowMs,
  }) {
    final dateDay =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final base = existing ??
        Session(
          id: sessionId,
          startTime: date.millisecondsSinceEpoch,
          endTime: date.millisecondsSinceEpoch + durationSecs * 1000,
          durationSecs: durationSecs,
          notes: null,
          dateDay: dateDay,
          locationLabel: null,
          lat: null,
          lng: null,
          createdAt: nowMs,
          updatedAt: nowMs,
        );
    return base.copyWith(
      // startTime/endTime must follow the edited date, not just dateDay — the
      // card, the re-opened editor, and exports all read startTime, while
      // calendar grouping + the heatmap group by dateDay. Updating only dateDay
      // left an edited session showing on two different days.
      startTime: date.millisecondsSinceEpoch,
      endTime: date.millisecondsSinceEpoch + durationSecs * 1000,
      durationSecs: durationSecs,
      notes: Value(notes.isEmpty ? null : notes),
      dateDay: dateDay,
      updatedAt: nowMs,
    );
  }
}

class _SessionEditSheetState extends ConsumerState<SessionEditSheet> {
  late int _hours;
  late int _minutes;
  late String _notes;
  late DateTime _date;
  Session? _session;

  // The values the editor opened with, so back knows whether there is any
  // typed work to keep.
  late final (int, int, String, DateTime) _initial;
  bool _saving = false;

  bool get _dirty => (_hours, _minutes, _notes, _date) != _initial;

  late FixedExtentScrollController _hoursController;
  late FixedExtentScrollController _minutesController;

  static final _dateFmt = DateFormat('EEEE, MMMM d');

  @override
  void initState() {
    super.initState();
    final s = widget.initialSession as Session?;
    _session = s;
    if (s != null) {
      _hours = s.durationSecs ~/ 3600;
      _minutes = (s.durationSecs % 3600) ~/ 60;
      _notes = s.notes ?? '';
      _date = DateTime.fromMillisecondsSinceEpoch(s.startTime);
    } else {
      _hours = 0;
      _minutes = 0;
      _notes = '';
      _date = DateTime.now();
    }
    _initial = (_hours, _minutes, _notes, _date);
    _hoursController = FixedExtentScrollController(initialItem: _hours);
    _minutesController = FixedExtentScrollController(initialItem: _minutes);
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  /// Back (app bar or system) keeps typed work: it saves through the same
  /// path as Save instead of dropping the edit (about-face-11), and it never
  /// asks "Save changes?". An edit that cannot be saved (a zero duration)
  /// leaves the stored session as it was and says so.
  Future<void> _onBack() async {
    if (_saving) return;
    final durationSecs = _hours * 3600 + _minutes * 60;
    if (durationSecs <= 0) {
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('Edit not saved: a session needs a duration.'),
      ));
      return;
    }
    final saved = await _save(fromBack: true);
    if (saved || !mounted) return;
    // A failed save must not trap the user behind back (every retry would
    // fail the same way). Leave, and say so. On an unsaved draft nothing is
    // lost: confirmSession keeps it in the timer for another try.
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger.showSnackBar(const SnackBar(
      content: Text('Edit not saved: the session couldn’t be written.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Session'),
          actions: [
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
        body: OhPage(
          padding: EdgeInsets.zero,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('Duration', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SpinnerPicker(
                    controller: _hoursController,
                    itemCount: 24,
                    label: 'h',
                    onChanged: (v) => setState(() => _hours = v),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      ':',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  _SpinnerPicker(
                    controller: _minutesController,
                    itemCount: 60,
                    label: 'm',
                    onChanged: (v) => setState(() => _minutes = v),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Date', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_dateFmt.format(_date)),
                trailing: const Icon(LucideIcons.calendarDays),
                onTap: _pickDate,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Notes (optional)',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                initialValue: _notes,
                maxLength: 100,
                decoration: const InputDecoration(
                  hintText: 'e.g. park day with co-op',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _notes = v),
              ),
              // A visible way to delete (the swipe on History is
              // unadvertised). Not offered for the timer's unsaved draft,
              // which has its own Discard.
              if (_session != null && !_isDraft) ...[
                const SizedBox(height: AppSpacing.xl),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    icon: const Icon(LucideIcons.trash2),
                    label: const Text('Delete session'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: _saving ? null : _delete,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool get _isDraft {
    final t = ref.read(timerNotifierProvider);
    return t is TimerStopped && t.session.id == widget.sessionId;
  }

  /// Deleting from here is deliberate, so it does not ask (fleet delete
  /// ruling). The editor closes and History offers an Undo that never
  /// times out; Undo writes the session back as it was stored.
  Future<void> _delete() async {
    final s = _session!;
    final repo = ref.read(sessionsRepositoryProvider);
    final undo = ref.read(sessionUndoControllerProvider);
    final timer = ref.read(timerNotifierProvider.notifier);
    _saving = true;
    final result = await repo.deleteSession(s.id);
    _saving = false;
    if (!mounted) return;
    final ok = result.fold((failure) {
      debugPrint("Couldn't delete the session: ${failure.message}");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Couldn’t delete the session. Please try again.'),
      ));
      return false;
    }, (_) => true);
    if (!ok) return;
    await timer.refreshWidget(s.dateDay);
    if (!mounted) return;
    context.pop();
    final label = Duration(seconds: s.durationSecs).toHoursLabel();
    final day = DateFormat('EEE, MMM d')
        .format(DateTime.fromMillisecondsSinceEpoch(s.startTime));
    undo.show(
      message: 'Deleted $label on $day',
      onUndo: () async {
        await repo.saveSession(s);
        await timer.refreshWidget(s.dateDay);
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  /// Saves and closes the sheet. Returns whether the write succeeded. From
  /// the Save action a failure keeps the sheet open to retry; from back
  /// ([fromBack]) the caller decides.
  Future<bool> _save({bool fromBack = false}) async {
    final durationSecs = _hours * 3600 + _minutes * 60;
    if (durationSecs <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duration must be greater than 0')),
      );
      return false;
    }
    if (durationSecs > 86400) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duration cannot exceed 24 hours')),
      );
      return false;
    }

    final now = DateTime.now();
    final dateDay =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

    final updated = SessionEditSheet.buildSessionForSave(
      existing: _session,
      sessionId: widget.sessionId,
      date: _date,
      durationSecs: durationSecs,
      notes: _notes,
      nowMs: now.millisecondsSinceEpoch,
    );

    _saving = true;
    final timerState = ref.read(timerNotifierProvider);
    final Either<StorageFailure, Unit> result;
    // Only the draft itself goes through confirmSession. Editing some other
    // session while a draft waits must not save it as "the draft" and clear
    // the real one.
    if (timerState is TimerStopped &&
        timerState.session.id == widget.sessionId) {
      result = await ref
          .read(timerNotifierProvider.notifier)
          .confirmSession(updated);
    } else {
      result = await ref.read(sessionsRepositoryProvider).saveSession(updated);
      if (result.isRight()) {
        final newBadges =
            await ref.read(badgesRepositoryProvider).checkAndAwardMilestones();
        if (newBadges.isNotEmpty) {
          ref.read(newlyEarnedBadgesProvider.notifier).state = newBadges;
        }
        await ref.read(timerNotifierProvider.notifier).refreshWidget(dateDay);
      }
    }

    _saving = false;
    if (!mounted) return result.isRight();
    // Don't silently pop on a failed write — surface it and keep the sheet open
    // so the user can retry instead of losing the session.
    // failure.message is the raw storage exception: log it, never show it.
    return result.fold(
      (failure) {
        debugPrint("Couldn't save the session: ${failure.message}");
        if (!fromBack) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Couldn’t save the session. Please try again."),
            ),
          );
        }
        return false;
      },
      (_) {
        context.pop();
        return true;
      },
    );
  }
}

class _SpinnerPicker extends StatelessWidget {
  const _SpinnerPicker({
    required this.controller,
    required this.itemCount,
    required this.label,
    required this.onChanged,
  });
  final FixedExtentScrollController controller;
  final int itemCount;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 120,
          width: 72,
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: 40,
            backgroundColor: Colors.transparent,
            onSelectedItemChanged: onChanged,
            children: List.generate(
              itemCount,
              (i) => Center(
                child: Text(
                  i.toString().padLeft(2, '0'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
