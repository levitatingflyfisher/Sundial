// lib/features/sessions/presentation/session_edit_sheet.dart
import 'package:drift/drift.dart' hide Table, Column;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/timer/domain/timer_state.dart';
import 'package:sundial/features/timer/presentation/timer_notifier.dart';
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
    _hoursController = FixedExtentScrollController(initialItem: _hours);
    _minutesController = FixedExtentScrollController(initialItem: _minutes);
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Session'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
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
          Text('Notes (optional)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: _notes,
            maxLength: 100,
            decoration: const InputDecoration(
              hintText: 'e.g. park day with co-op',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => _notes = v,
          ),
        ],
      ),
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

  Future<void> _save() async {
    final durationSecs = _hours * 3600 + _minutes * 60;
    if (durationSecs <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duration must be greater than 0')),
      );
      return;
    }
    if (durationSecs > 86400) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duration cannot exceed 24 hours')),
      );
      return;
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

    final timerState = ref.read(timerNotifierProvider);
    if (timerState is TimerStopped) {
      await ref.read(timerNotifierProvider.notifier).confirmSession(updated);
    } else {
      await ref.read(sessionsRepositoryProvider).saveSession(updated);
      final newBadges = await ref.read(badgesRepositoryProvider).checkAndAwardMilestones();
      if (newBadges.isNotEmpty) {
        ref.read(newlyEarnedBadgesProvider.notifier).state = newBadges;
      }
      await ref.read(badgesRepositoryProvider).revokeIfBelowMilestones();
      await ref.read(timerNotifierProvider.notifier).refreshWidget(dateDay);
    }

    if (context.mounted) context.pop();
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
