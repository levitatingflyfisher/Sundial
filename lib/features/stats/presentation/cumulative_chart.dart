// lib/features/stats/presentation/cumulative_chart.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial/core/providers/core_providers.dart';

class CumulativeChart extends ConsumerWidget {
  const CumulativeChart({super.key, this.profileId});

  /// When non-null, the chart only aggregates that profile's sessions plus
  /// any null-profile (Everyone) sessions. When null, every session counts.
  final String? profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref
        .watch(sessionsRepositoryProvider)
        .watchAllSessionsFiltered(profileId);
    return StreamBuilder(
      stream: stream,
      builder: (context, snap) {
        final sessions = snap.data ?? const [];

        // Bucket by year-month, build running total
        final Map<String, double> byMonth = {};
        for (final s in sessions) {
          final key = s.dateDay.substring(0, 7); // 'yyyy-MM'
          byMonth[key] = (byMonth[key] ?? 0) + s.durationSecs / 3600.0;
        }
        final keys = byMonth.keys.toList()..sort();
        double cum = 0;
        final points = [
          for (final k in keys) _Point(k, cum += byMonth[k]!),
        ];

        final cs = Theme.of(context).colorScheme;
        final totalLabel = points.isEmpty
            ? '0h total'
            : '${points.last.hours.toStringAsFixed(0)}h total';

        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hours outside — all time',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: CustomPaint(
                    painter: _CumulativePainter(
                      points: points,
                      lineColor: cs.primary,
                      labelColor: cs.onSurfaceVariant,
                      gridColor: cs.outlineVariant,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Point {
  const _Point(this.yearMonth, this.hours);
  final String yearMonth; // 'yyyy-MM'
  final double hours;
}

class _CumulativePainter extends CustomPainter {
  const _CumulativePainter({
    required this.points,
    required this.lineColor,
    required this.labelColor,
    required this.gridColor,
  });

  final List<_Point> points;
  final Color lineColor;
  final Color labelColor;
  final Color gridColor;

  static const _leftPad = 36.0;
  static const _bottomPad = 20.0;
  static const _topPad = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final chartW = size.width - _leftPad;
    final chartH = size.height - _bottomPad - _topPad;
    final maxH = points.isEmpty ? 0.0 : points.last.hours;

    // Y grid lines + labels at 0, 50%, 100%
    for (final frac in [0.0, 0.5, 1.0]) {
      final y = _topPad + chartH * (1 - frac);
      canvas.drawLine(
        Offset(_leftPad, y),
        Offset(size.width, y),
        Paint()
          ..color = gridColor.withValues(alpha: 0.5)
          ..strokeWidth = 0.5,
      );
      final label = maxH > 0 ? '${(maxH * frac).round()}h' : '0h';
      _drawText(canvas, label, 0, y - 7, color: labelColor, size: 9);
    }

    // Nothing more to draw with no data
    if (points.isEmpty || maxH == 0) return;

    final n = points.length;

    // Convert data points to canvas coordinates
    final offsets = List.generate(n, (i) {
      final x = n == 1 ? _leftPad + chartW / 2 : _leftPad + (i / (n - 1)) * chartW;
      final y = _topPad + chartH * (1 - points[i].hours / maxH);
      return Offset(x, y);
    });

    if (n == 1) {
      // Single month: just draw a dot
      canvas.drawCircle(offsets.first, 4, Paint()..color = lineColor);
      _drawText(canvas, _monthLabel(points.first.yearMonth),
          offsets.first.dx - 10, size.height - _bottomPad + 4,
          color: labelColor, size: 9);
      return;
    }

    // Fill path (gradient beneath the line)
    final fillPath = Path()..moveTo(offsets.first.dx, _topPad + chartH);
    fillPath.lineTo(offsets.first.dx, offsets.first.dy);
    _addBezier(fillPath, offsets);
    fillPath.lineTo(offsets.last.dx, _topPad + chartH);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.20),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(_leftPad, _topPad, chartW, chartH));
    canvas.drawPath(fillPath, fillPaint);

    // Line path
    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    _addBezier(linePath, offsets);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // X axis labels
    final labelIndices = _labelIndices(n);
    for (final i in labelIndices) {
      final label = _monthLabel(points[i].yearMonth);
      final x = _leftPad + (i / (n - 1)) * chartW;
      _drawText(canvas, label, x - 10, size.height - _bottomPad + 4,
          color: labelColor, size: 9);
    }
  }

  void _addBezier(Path path, List<Offset> pts) {
    for (int i = 1; i < pts.length; i++) {
      final dx = (pts[i].dx - pts[i - 1].dx) / 3;
      path.cubicTo(
        pts[i - 1].dx + dx, pts[i - 1].dy,
        pts[i].dx - dx, pts[i].dy,
        pts[i].dx, pts[i].dy,
      );
    }
  }

  List<int> _labelIndices(int n) {
    if (n <= 4) return List.generate(n, (i) => i);
    return {0, n ~/ 3, (2 * n) ~/ 3, n - 1}.toList()..sort();
  }

  String _monthLabel(String ym) {
    final parts = ym.split('-');
    const abbr = ['','Jan','Feb','Mar','Apr','May','Jun',
                   'Jul','Aug','Sep','Oct','Nov','Dec'];
    return "${abbr[int.parse(parts[1])]} '${parts[0].substring(2)}";
  }

  void _drawText(Canvas canvas, String text, double x, double y,
      {required Color color, double size = 10}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: size, color: color, fontWeight: FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(_CumulativePainter old) =>
      old.points != points || old.lineColor != lineColor;
}
