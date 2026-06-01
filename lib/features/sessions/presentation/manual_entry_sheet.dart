// lib/features/sessions/presentation/manual_entry_sheet.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/timer/presentation/timer_notifier.dart';
import 'package:sundial/shared/theme/app_spacing.dart';

class ManualEntrySheet extends ConsumerStatefulWidget {
  const ManualEntrySheet({super.key, this.initialDate});
  final DateTime? initialDate;

  @override
  ConsumerState<ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends ConsumerState<ManualEntrySheet> {
  int _hours = 0;
  int _minutes = 30;
  String _notes = '';
  late DateTime _date;

  late FixedExtentScrollController _hoursController;
  late FixedExtentScrollController _minutesController;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
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
        title: const Text('Add Time'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('How long?', style: Theme.of(context).textTheme.titleSmall),
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _date.year == DateTime.now().year &&
                      _date.month == DateTime.now().month &&
                      _date.day == DateTime.now().day
                  ? 'Today'
                  : '${_date.month}/${_date.day}/${_date.year}',
            ),
            subtitle: const Text('Date'),
            trailing: const Icon(LucideIcons.calendarCheck),
            onTap: _pickDate,
          ),
          TextField(
            maxLength: 100,
            decoration: const InputDecoration(
              hintText: 'Notes (optional)',
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
    if (durationSecs <= 0) return;
    final now = DateTime.now();
    final dateDay =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
    // Attribute the manual entry to the active profile. The Everyone
    // sentinel stores profileId=null so a single session counts once in
    // stats but appears in every profile's filtered view via the IS NULL
    // clause in watchAllFiltered — same rule as TimerNotifier.confirmSession.
    final activeProfile = ref.read(activeProfileIdProvider);
    final resolvedProfileId =
        activeProfile == kEveryoneProfileId ? null : activeProfile;
    final session = Session(
      id: const Uuid().v4(),
      startTime: _date.millisecondsSinceEpoch,
      endTime: _date.millisecondsSinceEpoch + durationSecs * 1000,
      durationSecs: durationSecs,
      notes: _notes.isEmpty ? null : _notes,
      dateDay: dateDay,
      profileId: resolvedProfileId,
      locationLabel: null, lat: null, lng: null,
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );
    await ref.read(sessionsRepositoryProvider).saveSession(session);
    final newBadges = await ref.read(badgesRepositoryProvider).checkAndAwardMilestones();
    if (newBadges.isNotEmpty) {
      ref.read(newlyEarnedBadgesProvider.notifier).state = newBadges;
    }
    await ref.read(timerNotifierProvider.notifier).refreshWidget(dateDay);
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
