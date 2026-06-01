// lib/features/sessions/presentation/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart' show Profile, Session;
import 'package:sundial/features/profiles/presentation/profiles_screen.dart';
import 'package:sundial/features/timer/presentation/timer_notifier.dart';
import 'package:sundial/shared/extensions/duration_ext.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';
import 'package:sundial/shared/theme/app_colors.dart';
import 'package:sundial/shared/theme/app_spacing.dart';
import 'session_card.dart';

enum _DateFilter { all, thisWeek, thisMonth }

enum _ViewMode { list, calendar }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _DateFilter _filter = _DateFilter.all;
  _ViewMode _viewMode = _ViewMode.calendar;
  DateTime _calendarMonth =
      DateTime(DateTime.now().year, DateTime.now().month);
  String? _calendarSelectedDay;
  String? _profileFilter; // null = all profiles

  static final _monthFmt = DateFormat('MMMM yyyy');

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesFilter(Session session, WeekStart weekStartPref) {
    if (_filter == _DateFilter.all) return true;
    final now = DateTime.now();
    final day = session.dateDay as String;
    final date = DateTime.parse(day);
    if (_filter == _DateFilter.thisMonth) {
      return date.year == now.year && date.month == now.month;
    }
    // thisWeek: respects user's week start preference
    final int daysFromStart;
    if (weekStartPref == WeekStart.sunday) {
      daysFromStart = now.weekday % 7; // Sun=0, Mon=1, ..., Sat=6
    } else {
      daysFromStart = now.weekday - 1; // Mon=0, Tue=1, ..., Sun=6
    }
    final startDate = now.subtract(Duration(days: daysFromStart));
    final weekStart = DateTime(startDate.year, startDate.month, startDate.day);
    final weekEnd = weekStart.add(const Duration(days: 7));
    return !date.isBefore(weekStart) && date.isBefore(weekEnd);
  }

  @override
  Widget build(BuildContext context) {
    final sessionsStream = ref
        .watch(sessionsRepositoryProvider)
        .watchAllSessionsFiltered(_profileFilter);
    final profilesAsync = ref.watch(profilesListProvider);
    final profiles = profilesAsync.valueOrNull ?? [];
    final prefsAsync = ref.watch(userPrefsProvider);
    final weekStart = prefsAsync.valueOrNull?.weekStart ?? WeekStart.sunday;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // Toolbar row: filter chips or month nav + view toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.xs),
            child: Row(
              children: [
                if (_viewMode == _ViewMode.list) ...[
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        spacing: AppSpacing.xs,
                        children: _DateFilter.values.map((f) {
                          final label = switch (f) {
                            _DateFilter.all => 'All',
                            _DateFilter.thisWeek => 'This week',
                            _DateFilter.thisMonth => 'This month',
                          };
                          return FilterChip(
                            label: Text(label),
                            selected: _filter == f,
                            onSelected: (_) =>
                                setState(() => _filter = f),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft, size: 20),
                    onPressed: () => setState(() {
                      _calendarMonth = DateTime(
                          _calendarMonth.year, _calendarMonth.month - 1);
                      _calendarSelectedDay = null;
                    }),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _showMonthYearPicker,
                      child: Text(
                        _monthFmt.format(_calendarMonth),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.dotted,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.chevronRight, size: 20),
                    onPressed: () => setState(() {
                      _calendarMonth = DateTime(
                          _calendarMonth.year, _calendarMonth.month + 1);
                      _calendarSelectedDay = null;
                    }),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    _viewMode == _ViewMode.list
                        ? LucideIcons.calendarDays
                        : LucideIcons.list,
                    size: 20,
                  ),
                  tooltip: _viewMode == _ViewMode.list
                      ? 'Calendar view'
                      : 'List view',
                  onPressed: () => setState(() {
                    _viewMode = _viewMode == _ViewMode.list
                        ? _ViewMode.calendar
                        : _ViewMode.list;
                    _calendarSelectedDay = null;
                    _calendarMonth = DateTime(
                        DateTime.now().year, DateTime.now().month);
                  }),
                ),
              ],
            ),
          ),
          // Profile filter chips — only shown when 2+ profiles exist.
          if (profiles.length >= 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
              child: SingleChildScrollView(
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
            ),
          if (_viewMode == _ViewMode.list)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search notes…',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            FocusScope.of(context).unfocus();
                          },
                        ),
                  isDense: true,
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder(
              stream: sessionsStream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data!;

                if (_viewMode == _ViewMode.calendar) {
                  return GestureDetector(
                    onHorizontalDragEnd: (details) {
                      final v = details.primaryVelocity ?? 0;
                      if (v < -200) {
                        setState(() {
                          _calendarMonth = DateTime(
                              _calendarMonth.year, _calendarMonth.month + 1);
                          _calendarSelectedDay = null;
                        });
                      } else if (v > 200) {
                        setState(() {
                          _calendarMonth = DateTime(
                              _calendarMonth.year, _calendarMonth.month - 1);
                          _calendarSelectedDay = null;
                        });
                      }
                    },
                    child: _buildCalendarView(all, context, cs, profiles, weekStart),
                  );
                }

                // List mode
                final sessions = all.where((s) {
                  final matchesQuery = _query.isEmpty ||
                      (s.notes?.toLowerCase().contains(_query) ?? false);
                  return matchesQuery && _matchesFilter(s, weekStart);
                }).toList();

                if (all.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.sun, size: 48),
                        SizedBox(height: AppSpacing.md),
                        Text('No sessions yet — go outside!'),
                      ],
                    ),
                  );
                }

                if (sessions.isEmpty) {
                  final reason = _query.isNotEmpty
                      ? 'No sessions match "$_query"'
                      : _filter == _DateFilter.thisWeek
                          ? 'No sessions this week'
                          : 'No sessions this month';
                  return Center(
                    child: Text(
                      reason,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = sessions[i];
                    // In Everyone view with 2+ profiles, show a colored dot
                    // so it's clear who a session belongs to.
                    final owner = (profiles.length >= 2 &&
                            _profileFilter == null &&
                            s.profileId != null)
                        ? profiles.cast<Profile?>().firstWhere(
                            (p) => p?.id == s.profileId,
                            orElse: () => null)
                        : null;
                    return SessionCard(
                      session: s,
                      profile: owner,
                      showEveryoneTag: _profileFilter != null,
                      onTap: () =>
                          context.push('/sessions/${s.id}/edit', extra: s),
                      onDelete: () async {
                        await ref
                            .read(sessionsRepositoryProvider)
                            .deleteSession(s.id);
                        await ref
                            .read(badgesRepositoryProvider)
                            .revokeIfBelowMilestones();
                        await ref
                            .read(timerNotifierProvider.notifier)
                            .refreshWidget(s.dateDay);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final initialDate =
              _viewMode == _ViewMode.calendar && _calendarSelectedDay != null
                  ? DateTime.parse(_calendarSelectedDay!)
                  : null;
          context.push('/sessions/add', extra: initialDate);
        },
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  Future<void> _showMonthYearPicker() async {
    int pickerYear = _calendarMonth.year;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.chevronLeft, size: 18),
                onPressed: () => setDialogState(() => pickerYear--),
              ),
              Text('$pickerYear',
                  style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(LucideIcons.chevronRight, size: 18),
                onPressed: () => setDialogState(() => pickerYear++),
              ),
            ],
          ),
          contentPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: SizedBox(
            width: 280,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: List.generate(12, (i) {
                final month = i + 1;
                final isSelected = pickerYear == _calendarMonth.year &&
                    month == _calendarMonth.month;
                final cs = Theme.of(context).colorScheme;
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _calendarMonth = DateTime(pickerYear, month);
                      _calendarSelectedDay = null;
                    });
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? cs.primary : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      DateFormat.MMM().format(DateTime(2000, month)),
                      style: TextStyle(
                        color: isSelected ? cs.onPrimary : null,
                        fontWeight:
                            isSelected ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView(
      List<Session> all,
      BuildContext context,
      ColorScheme cs,
      List<Profile> profiles,
      WeekStart weekStart) {
    final monthPrefix =
        '${_calendarMonth.year}-${_calendarMonth.month.toString().padLeft(2, '0')}';

    // Group sessions by dateDay for the current month
    final sessionsByDay = <String, List<Session>>{};
    for (final s in all) {
      final day = s.dateDay as String;
      if (day.startsWith(monthPrefix)) {
        sessionsByDay.putIfAbsent(day, () => []).add(s);
      }
    }

    // Sessions to show in the detail list below the grid
    final List<Session> detailSessions;
    final String emptyMsg;
    if (_calendarSelectedDay != null) {
      detailSessions = List<Session>.from(
          sessionsByDay[_calendarSelectedDay] ?? [])
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
      emptyMsg = 'No sessions on this day';
    } else {
      detailSessions = sessionsByDay.values
          .expand((e) => e)
          .toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
      emptyMsg =
          'No sessions in ${DateFormat('MMMM').format(_calendarMonth)}';
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
          child: _buildCalendarGrid(sessionsByDay, cs, weekStart),
        ),
        const Divider(height: 1),
        Expanded(
          child: detailSessions.isEmpty
              ? Center(
                  child: Text(
                    emptyMsg,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                )
              : ListView.separated(
                  itemCount: detailSessions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = detailSessions[i];
                    // In Everyone view with 2+ profiles, show a colored dot
                    // so it's clear who a session belongs to.
                    final owner = (profiles.length >= 2 &&
                            _profileFilter == null &&
                            s.profileId != null)
                        ? profiles.cast<Profile?>().firstWhere(
                            (p) => p?.id == s.profileId,
                            orElse: () => null)
                        : null;
                    return SessionCard(
                      session: s,
                      profile: owner,
                      showEveryoneTag: _profileFilter != null,
                      onTap: () =>
                          context.push('/sessions/${s.id}/edit', extra: s),
                      onDelete: () async {
                        await ref
                            .read(sessionsRepositoryProvider)
                            .deleteSession(s.id);
                        await ref
                            .read(badgesRepositoryProvider)
                            .revokeIfBelowMilestones();
                        await ref
                            .read(timerNotifierProvider.notifier)
                            .refreshWidget(s.dateDay);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(
      Map<String, List<Session>> sessionsByDay, ColorScheme cs,
      WeekStart weekStartPref) {
    final now = DateTime.now();
    final firstDay =
        DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    // weekday: 1=Mon...7=Sun
    final startOffset = weekStartPref == WeekStart.sunday
        ? firstDay.weekday % 7      // Sun=0, Mon=1, ..., Sat=6
        : firstDay.weekday - 1;     // Mon=0, Tue=1, ..., Sun=6
    final rowCount = ((startOffset + daysInMonth) / 7).ceil();

    final dayLabels = weekStartPref == WeekStart.sunday
        ? const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
        : const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Day-of-week header
        Row(
          children: dayLabels
              .map((l) => Expanded(
                    child: Center(
                      child: Text(
                        l,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        // Week rows
        ...List.generate(rowCount, (row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(7, (col) {
                final dayNum = row * 7 + col - startOffset + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox());
                }
                final dateStr =
                    '${_calendarMonth.year}-${_calendarMonth.month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                final hasSessions = sessionsByDay.containsKey(dateStr);
                final isSelected = _calendarSelectedDay == dateStr;
                final isToday = now.year == _calendarMonth.year &&
                    now.month == _calendarMonth.month &&
                    now.day == dayNum;

                final totalSecs = hasSessions
                    ? sessionsByDay[dateStr]!
                        .fold(0, (sum, s) => sum + s.durationSecs)
                    : 0;
                final durationLabel = hasSessions
                    ? Duration(seconds: totalSecs).toHoursLabel()
                    : null;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _calendarSelectedDay = isSelected ? null : dateStr;
                    }),
                    child: Container(
                      height: 48,
                      margin:
                          const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primary
                            : hasSessions
                                ? AppColors.sage500
                                    .withValues(alpha: 0.25)
                                : null,
                        border: isToday && !isSelected
                            ? Border.all(
                                color: cs.primary, width: 1.5)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: hasSessions
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color:
                                  isSelected ? cs.onPrimary : null,
                            ),
                          ),
                          if (durationLabel != null)
                            Text(
                              durationLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? cs.onPrimary
                                        .withValues(alpha: 0.85)
                                    : cs.onSurfaceVariant,
                                height: 1.2,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }
}
