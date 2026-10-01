// lib/features/sessions/presentation/history_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart' show Profile, Session;
import 'package:sundial/features/profiles/presentation/profiles_screen.dart';
import 'package:sundial/features/timer/presentation/timer_notifier.dart';
import 'package:sundial/shared/extensions/duration_ext.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';
import 'package:sundial/shared/theme/app_colors.dart';
import 'package:sundial/shared/theme/app_spacing.dart';
import 'session_card.dart';
import 'session_undo.dart';

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
      setState(() {
        _query = _searchCtrl.text.trim().toLowerCase();
        // A calendar has no meaning for a text search (Q-D3): typing a
        // query shows the List with the matches.
        if (_query.isNotEmpty && _viewMode == _ViewMode.calendar) {
          _viewMode = _ViewMode.list;
          _calendarSelectedDay = null;
        }
      });
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
    final day = session.dateDay;
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
          // The view switch: two worded segments, each an absolute choice
          // (finding 10: one icon named only in a tooltip). Switching keeps
          // the browsed month.
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: SegmentedButton<_ViewMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: _ViewMode.calendar,
                    icon: Icon(LucideIcons.calendarDays, size: 18),
                    label: _SegmentWord('Calendar'),
                  ),
                  ButtonSegment(
                    value: _ViewMode.list,
                    icon: Icon(LucideIcons.list, size: 18),
                    label: _SegmentWord('List'),
                  ),
                ],
                selected: {_viewMode},
                onSelectionChanged: (v) {
                  // Back to the calendar drops the query it cannot show.
                  if (v.single == _ViewMode.calendar) _searchCtrl.clear();
                  setState(() {
                    _viewMode = v.single;
                    _calendarSelectedDay = null;
                  });
                },
              ),
            ),
          ),
          // Toolbar row: filter chips or month nav
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
          // Above both views: on the calendar, typing switches to the List.
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
                        Text('No sessions yet. Go outside!'),
                      ],
                    ),
                  );
                }

                if (sessions.isEmpty) {
                  final reason = _query.isNotEmpty
                      ? 'No sessions match “$_query”'
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
      // A session deleted from Edit Session offers its Undo here; it never
      // times out (fleet delete ruling).
      bottomNavigationBar:
          OhUndoBar(controller: ref.watch(sessionUndoControllerProvider)),
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
      final day = s.dateDay;
      if (day.startsWith(monthPrefix)) {
        sessionsByDay.putIfAbsent(day, () => []).add(s);
      }
    }

    // Sessions to show in the detail list below the grid
    final List<Session> detailSessions;
    final String emptyMsg;
    if (_calendarSelectedDay != null) {
      detailSessions =
          List<Session>.from(sessionsByDay[_calendarSelectedDay] ?? [])
            ..sort((a, b) => b.startTime.compareTo(a.startTime));
      emptyMsg = 'No sessions on this day';
    } else {
      detailSessions = sessionsByDay.values.expand((e) => e).toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
      emptyMsg = 'No sessions in ${DateFormat('MMMM').format(_calendarMonth)}';
    }

    // One scroll for the grid and the day's sessions: at large text the
    // grid alone can be taller than the screen, and a fixed grid above an
    // Expanded list overflowed (batch 1's 320dp x 2-3 finding).
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
            child: _buildCalendarGrid(sessionsByDay, cs, weekStart),
          ),
        ),
        const SliverToBoxAdapter(child: Divider(height: 1)),
        if (detailSessions.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  emptyMsg,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ),
          )
        else
          SliverList.separated(
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
                onTap: () => context.push('/sessions/${s.id}/edit', extra: s),
                onDelete: () async {
                  await ref
                      .read(sessionsRepositoryProvider)
                      .deleteSession(s.id);
                  await ref
                      .read(timerNotifierProvider.notifier)
                      .refreshWidget(s.dateDay);
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildCalendarGrid(Map<String, List<Session>> sessionsByDay,
      ColorScheme cs, WeekStart weekStartPref) {
    final now = DateTime.now();
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    // weekday: 1=Mon...7=Sun
    final startOffset = weekStartPref == WeekStart.sunday
        ? firstDay.weekday % 7 // Sun=0, Mon=1, ..., Sat=6
        : firstDay.weekday - 1; // Mon=0, Tue=1, ..., Sun=6
    final rowCount = ((startOffset + daysInMonth) / 7).ceil();

    // A week row is as tall as its two lines need at this text size (the
    // date at full scale, the duration capped at 1.3x: it is secondary, and
    // the list under the grid repeats it), never less than a 48 px target.
    // A fixed 48 px clipped both from 2x up at 320dp.
    final scaler = MediaQuery.textScalerOf(context);
    final durationScaler = scaler.clamp(maxScaleFactor: 1.3);
    final cellHeight = math.max(
      48.0,
      8 + scaler.scale(12) * 1.25 + durationScaler.scale(11) * 1.25,
    );

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
                      // Two letters on one line, scaled down rather than
                      // broken as "S/u" at large text.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          l,
                          maxLines: 1,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
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
            child: SizedBox(
              height: cellHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cs.primary
                              : hasSessions
                                  ? AppColors.sage500.withValues(alpha: 0.25)
                                  : null,
                          border: isToday && !isSelected
                              ? Border.all(color: cs.primary, width: 1.5)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // A cell is a seventh of the width: the date and
                        // its total scale down together to fit rather than
                        // wrap or clip; the row height grows with the text.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$dayNum',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: hasSessions
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected ? cs.onPrimary : null,
                                ),
                              ),
                              if (durationLabel != null)
                                Text(
                                  durationLabel,
                                  textScaler: durationScaler,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? cs.onPrimary.withValues(alpha: 0.85)
                                        : cs.onSurfaceVariant,
                                    height: 1.2,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// A segment's word, kept whole: past the segment's width it shrinks to fit
/// rather than breaking mid-word ("Calen / dar" at 320 dp and 2x-3x text).
class _SegmentWord extends StatelessWidget {
  const _SegmentWord(this.word);
  final String word;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(word, maxLines: 1, softWrap: false),
      );
}
