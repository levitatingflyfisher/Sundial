// lib/features/stats/presentation/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/features/badges/presentation/badge_shelf.dart';
import 'package:sundial/features/profiles/presentation/profiles_screen.dart';
import 'package:sundial/shared/extensions/duration_ext.dart';
import 'package:sundial/shared/theme/app_colors.dart';
import 'package:sundial/shared/theme/app_spacing.dart';
import 'cumulative_chart.dart';
import 'heatmap_chart.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  // null = Everyone (no filter). Local to this screen — deliberately does
  // NOT touch activeProfileIdProvider so "viewing Dad's stats" doesn't
  // switch the global active profile used by the timer.
  String? _profileFilter;

  @override
  void initState() {
    super.initState();
    // Guard against the widget being disposed before the microtask runs
    // (e.g. user navigates away quickly, or test tears down the tree).
    Future(() {
      if (!mounted) return;
      ref.read(badgesRepositoryProvider).revokeIfBelowMilestones();
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final yearKey = '${now.year}';

    final repo = ref.watch(sessionsRepositoryProvider);
    final prefsAsync = ref.watch(userPrefsProvider);
    final annualGoal = prefsAsync.valueOrNull?.annualGoalHours ?? 1000;
    final monthlyGoal = prefsAsync.valueOrNull?.monthlyGoalHours;
    final profilesAsync = ref.watch(profilesListProvider);
    final profiles = profilesAsync.valueOrNull ?? [];

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Profile filter chips — only shown when 2+ profiles exist.
          // Same rule as HistoryScreen so solo users never see the row.
          if (profiles.length >= 2) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: AppSpacing.xs,
                children: [
                  FilterChip(
                    label: const Text('Everyone'),
                    selected: _profileFilter == null,
                    onSelected: (_) =>
                        setState(() => _profileFilter = null),
                    visualDensity: VisualDensity.compact,
                  ),
                  ...profiles.map((p) => FilterChip(
                        avatar: ProfileAvatar(profile: p, size: 18),
                        label: Text(p.name),
                        selected: _profileFilter == p.id,
                        onSelected: (_) =>
                            setState(() => _profileFilter = p.id),
                        visualDensity: VisualDensity.compact,
                      )),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          CumulativeChart(profileId: _profileFilter),
          const SizedBox(height: AppSpacing.lg),
          HeatmapChart(profileId: _profileFilter),
          const SizedBox(height: AppSpacing.lg),
          _StatCard(
            label: 'Today',
            stream: repo.watchSecondsForDayFiltered(todayKey, _profileFilter),
          ),
          const SizedBox(height: AppSpacing.md),
          _StatCard(
            label: 'This Month',
            stream: repo.watchSecondsForYearMonthFiltered(
              monthKey,
              _profileFilter,
            ),
            goalHours: monthlyGoal,
          ),
          const SizedBox(height: AppSpacing.md),
          _StatCard(
            label: 'This Year',
            stream: repo.watchSecondsForYearFiltered(yearKey, _profileFilter),
            goalHours: annualGoal,
          ),
          const SizedBox(height: AppSpacing.md),
          _MonthlyBreakdown(profileId: _profileFilter),
          const SizedBox(height: AppSpacing.md),
          _StatCard(
            label: 'All Time',
            stream: repo.watchAllTimeSecondsFiltered(_profileFilter),
          ),
          const SizedBox(height: AppSpacing.xl),
          const BadgeShelf(),
        ],
      ),
    );
  }
}

// ── Monthly breakdown ────────────────────────────────────────────────────────

class _MonthlyBreakdown extends ConsumerWidget {
  const _MonthlyBreakdown({this.profileId});
  final String? profileId;

  static const _labels = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final stream = ref
        .watch(sessionsRepositoryProvider)
        .watchAllSessionsFiltered(profileId);
    return StreamBuilder(
      stream: stream,
      builder: (context, snap) {
        final sessions = snap.data ?? const [];
        final yearPrefix = '${now.year}-';
        final Map<int, int> byMonth = {};
        for (final s in sessions) {
          if (!s.dateDay.startsWith(yearPrefix)) continue;
          final m = int.tryParse(s.dateDay.substring(5, 7));
          if (m != null) byMonth[m] = (byMonth[m] ?? 0) + s.durationSecs;
        }
        final maxSecs = byMonth.values.fold(0, (a, b) => a > b ? a : b);
        final cs = Theme.of(context).colorScheme;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${now.year} by month',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...List.generate(now.month, (i) {
                  final month = i + 1;
                  final secs = byMonth[month] ?? 0;
                  final frac =
                      maxSecs > 0 ? (secs / maxSecs).clamp(0.0, 1.0) : 0.0;
                  final isCurrent = month == now.month;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            _labels[i],
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: isCurrent
                                      ? cs.primary
                                      : cs.onSurfaceVariant,
                                  fontWeight: isCurrent
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: frac,
                              minHeight: 8,
                              backgroundColor: cs.surfaceContainerHighest,
                              color: cs.primary
                                  .withValues(alpha: isCurrent ? 1.0 : 0.55),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: Text(
                            secs > 0
                                ? Duration(seconds: secs).toHoursLabel()
                                : '—',
                            textAlign: TextAlign.right,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: secs > 0
                                      ? cs.onSurface
                                      : cs.onSurfaceVariant
                                          .withValues(alpha: 0.4),
                                ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.stream, this.goalHours});
  final String label;
  final Stream<int> stream;
  final int? goalHours;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: StreamBuilder<int>(
          stream: stream,
          builder: (context, snap) {
            final secs = snap.data ?? 0;
            final dur = Duration(seconds: secs);
            final progress = goalHours != null
                ? (secs / (goalHours! * 3600)).clamp(0.0, 1.0)
                : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  dur.toHoursLabel(),
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (progress != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    color: _progressColor(progress),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% of ${goalHours}h goal',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Color _progressColor(double p) {
    if (p >= 0.85) return AppColors.onPace;
    if (p >= 0.60) return AppColors.slightlyBehind;
    return AppColors.behind;
  }
}
