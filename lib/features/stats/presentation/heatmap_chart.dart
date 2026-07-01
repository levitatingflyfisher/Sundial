// lib/features/stats/presentation/heatmap_chart.dart
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';

class HeatmapChart extends ConsumerStatefulWidget {
  const HeatmapChart({super.key, this.profileId});

  /// When non-null, the heatmap only aggregates that profile's sessions plus
  /// any null-profile (Everyone) sessions. When null, every session counts.
  final String? profileId;

  static const _cellSize = 10.0;
  static const _cellGap = 2.0;
  static const _stride = _cellSize + _cellGap;
  static const _labelH = 18.0;
  static const _weeks = 52;

  @override
  ConsumerState<HeatmapChart> createState() => _HeatmapChartState();
}

class _HeatmapChartState extends ConsumerState<HeatmapChart> {
  final _scrollCtrl = ScrollController();
  bool _didScroll = false;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (_didScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      _didScroll = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(userPrefsProvider);
    final weekStart = prefsAsync.valueOrNull?.weekStart ?? WeekStart.sunday;
    final weekStartDay = weekStart == WeekStart.sunday
        ? DateTime.sunday
        : DateTime.monday;
    final stream = ref
        .watch(sessionsRepositoryProvider)
        .watchAllSessionsFiltered(widget.profileId);
    return StreamBuilder(
      stream: stream,
      builder: (context, snap) {
        final sessions = snap.data ?? const [];
        final Map<String, int> byDay = {};
        for (final s in sessions) {
          byDay[s.dateDay] = (byDay[s.dateDay] ?? 0) + s.durationSecs;
        }
        _scrollToEnd();
        final cs = Theme.of(context).colorScheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 12 months',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _scrollCtrl,
              child: SizedBox(
                width: (HeatmapChart._weeks + 1) * HeatmapChart._stride +
                    HeatmapChart._cellSize,
                height:
                    HeatmapChart._labelH + 7 * HeatmapChart._stride,
                child: CustomPaint(
                  painter: _HeatmapPainter(
                    byDay: byDay,
                    // clock.now() so tests can pin the heatmap's today
                    // boundary with withClock (date-stable goldens).
                    today: clock.now(),
                    weekStartDay: weekStartDay,
                    activeColor: cs.primary,
                    emptyColor: cs.surfaceContainerHighest,
                    labelColor: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  const _HeatmapPainter({
    required this.byDay,
    required this.today,
    required this.weekStartDay,
    required this.activeColor,
    required this.emptyColor,
    required this.labelColor,
  });

  final Map<String, int> byDay;
  final DateTime today;
  final int weekStartDay;
  final Color activeColor;
  final Color emptyColor;
  final Color labelColor;

  static const _cellSize = HeatmapChart._cellSize;
  static const _stride = HeatmapChart._stride;
  static const _labelH = HeatmapChart._labelH;
  static const _weeks = HeatmapChart._weeks;
  // Minimum horizontal gap between month label left edges (3 chars ~20px).
  static const _minLabelGap = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final start = _startWeek();
    String? lastMonth;
    double lastLabelX = -999;

    for (int col = 0; col <= _weeks; col++) {
      final firstDay = start.add(Duration(days: col * 7));
      if (firstDay.isAfter(today)) break;

      final monthStr = _monthAbbr(firstDay.month);
      final x = col * _stride;
      if (monthStr != lastMonth && x - lastLabelX >= _minLabelGap) {
        lastMonth = monthStr;
        lastLabelX = x;
        _drawLabel(canvas, monthStr, x);
      }

      for (int row = 0; row < 7; row++) {
        final day = firstDay.add(Duration(days: row));
        if (day.isAfter(today)) break;

        final key = _fmt(day);
        final secs = byDay[key] ?? 0;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x,
            _labelH + row * _stride,
            _cellSize,
            _cellSize,
          ),
          const Radius.circular(2),
        );
        canvas.drawRRect(rect, Paint()..color = _color(secs));
      }
    }
  }

  DateTime _startWeek() {
    var d = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: _weeks * 7));
    while (d.weekday != weekStartDay) {
      d = d.subtract(const Duration(days: 1));
    }
    return d;
  }

  Color _color(int secs) {
    if (secs == 0) return emptyColor;
    if (secs < 1800) return activeColor.withValues(alpha: 0.25);
    if (secs < 5400) return activeColor.withValues(alpha: 0.55);
    if (secs < 10800) return activeColor.withValues(alpha: 0.80);
    return activeColor;
  }

  void _drawLabel(Canvas canvas, String text, double x) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 10,
          color: labelColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, 0));
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _monthAbbr(int m) =>
      const ['Jan','Feb','Mar','Apr','May','Jun',
             'Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      old.byDay != byDay ||
      old.today != today ||
      old.weekStartDay != weekStartDay ||
      old.activeColor != activeColor ||
      old.emptyColor != emptyColor;
}
