// lib/features/settings/presentation/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';
import 'package:sundial/shared/theme/app_spacing.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(userPrefsProvider);

    return Scaffold(
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (prefs) => _SettingsList(prefs: prefs),
      ),
    );
  }
}

class _SettingsList extends ConsumerWidget {
  const _SettingsList({required this.prefs});
  final UserPrefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(settingsRepositoryProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const _SectionHeader('Goals'),
        ListTile(
          title: const Text('Annual goal'),
          trailing: Text('${prefs.annualGoalHours}h'),
          onTap: () => _editGoal(
            context, ref,
            title: 'Annual goal (hours)',
            current: prefs.annualGoalHours,
            onSave: (v) => repo.setAnnualGoalHours(v!),
          ),
        ),
        ListTile(
          title: const Text('Monthly goal'),
          trailing: Text(prefs.monthlyGoalHours != null
              ? '${prefs.monthlyGoalHours}h'
              : 'Not set'),
          onTap: () => _editGoal(
            context, ref,
            title: 'Monthly goal (hours)',
            current: prefs.monthlyGoalHours,
            onSave: (v) => repo.setMonthlyGoalHours(v),
            allowClear: true,
          ),
        ),
        const _SectionHeader('Timer'),
        SwitchListTile(
          title: const Text('Auto-stop'),
          subtitle: Text('Stop after ${prefs.autoStopThresholdHours}h'),
          value: prefs.autoStopEnabled,
          onChanged: (v) => repo.setAutoStop(
            enabled: v,
            thresholdHours: prefs.autoStopThresholdHours,
          ),
        ),
        const _SectionHeader('Appearance'),
        SwitchListTile(
          title: const Text('Dark mode'),
          value: prefs.isDarkMode,
          onChanged: repo.setDarkMode,
        ),
        if (prefs.appMode == AppMode.flow)
          ListTile(
            title: const Text('Timer face'),
            trailing: Text(_styleLabel(prefs.flowTimerStyle)),
            onTap: () => _pickTimerFace(context, ref, prefs.flowTimerStyle),
          ),
        ListTile(
          title: const Text('Week starts on'),
          trailing: SegmentedButton<WeekStart>(
            segments: const [
              ButtonSegment(value: WeekStart.sunday, label: Text('Sun')),
              ButtonSegment(value: WeekStart.monday, label: Text('Mon')),
            ],
            selected: {prefs.weekStart},
            onSelectionChanged: (v) => repo.setWeekStart(v.first),
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        const _SectionHeader('People'),
        ListTile(
          leading: const Icon(LucideIcons.users),
          title: const Text('Manage people'),
          subtitle: const Text('Track time for family members individually'),
          onTap: () => context.push('/settings/profiles'),
        ),
        const _SectionHeader('Data'),
        ListTile(
          leading: const Icon(LucideIcons.hardDriveDownload),
          title: const Text('Backup & Restore'),
          onTap: () => context.push('/export'),
        ),
      ],
    );
  }

  String _styleLabel(FlowTimerStyle s) => switch (s) {
        FlowTimerStyle.gnomon => 'Gnomon (default)',
        FlowTimerStyle.arc => 'Arc sweep',
        FlowTimerStyle.dualRing => 'Dual ring',
      };

  Future<void> _editGoal(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required int? current,
    required Future<void> Function(int?) onSave,
    bool allowClear = false,
  }) async {
    final controller = TextEditingController(text: current?.toString() ?? '');
    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          if (allowClear && current != null)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(-1),
              child: const Text('Clear'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(int.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    if (result == -1) {
      await onSave(null); // clear
    } else if (result > 0) {
      await onSave(result);
    }
  }

  Future<void> _pickTimerFace(
      BuildContext context, WidgetRef ref, FlowTimerStyle current) async {
    final picked = await showDialog<FlowTimerStyle>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Timer face'),
        children: FlowTimerStyle.values
            .map((s) => SimpleDialogOption(
                  onPressed: () => Navigator.of(ctx).pop(s),
                  child: Row(
                    children: [
                      if (s == current) const Icon(LucideIcons.check, size: 16),
                      const SizedBox(width: 8),
                      Text(switch (s) {
                        FlowTimerStyle.gnomon => 'Gnomon (default)',
                        FlowTimerStyle.arc => 'Arc sweep',
                        FlowTimerStyle.dualRing => 'Dual ring',
                      }),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
    if (picked != null) {
      await ref.read(settingsRepositoryProvider).setFlowTimerStyle(picked);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        top: AppSpacing.lg,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
