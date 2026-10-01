import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';
import 'package:sundial/shared/extensions/duration_ext.dart';

/// Where the session stands on the dial (visual-04, ruling Q-D5): one full
/// sweep is [lapLength] (3h), and past it the arc wraps for another lap
/// instead of standing still. Exactly one lap is a full first sweep, not an
/// empty second.
({double progress, int lap}) sessionLap(Duration elapsed, Duration lapLength) {
  final lapSecs = lapLength.inSeconds;
  final secs = elapsed.inSeconds;
  if (lapSecs <= 0 || secs <= 0) return (progress: 0.0, lap: 1);
  if (secs % lapSecs == 0) return (progress: 1.0, lap: secs ~/ lapSecs);
  return (progress: (secs % lapSecs) / lapSecs, lap: secs ~/ lapSecs + 1);
}

/// "3h" (or "90m"): a lap's length as the face prints it.
String _lapLength(Duration d) =>
    d.inMinutes % 60 == 0 ? '${d.inHours}h' : '${d.inMinutes}m';

/// The face's statement of its own scale, with the lap once past the first.
String _scaleCaption(Duration elapsed, Duration lapLength) {
  final l = sessionLap(elapsed, lapLength);
  final scale = 'one sweep = ${_lapLength(lapLength)}';
  return l.lap > 1 ? 'Lap ${l.lap} · $scale' : 'One sweep = ${_lapLength(lapLength)}';
}

/// Draws [text] centred on [pos] (the faces' small print), at the reader's
/// text size ([scaler], capped at 2x by the face).
///
/// [maxWidth] keeps it inside the dial: at large text it wraps onto a second
/// line instead of running across the ring.
void _paintCaption(Canvas c, Offset pos, String text, Color color,
    [TextScaler scaler = TextScaler.noScaling,
    double maxWidth = double.infinity]) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    textScaler: scaler,
  )..layout(maxWidth: maxWidth);
  tp.paint(c, pos.translate(-tp.width / 2, -tp.height / 2));
}

class SundialFace extends StatefulWidget {
  const SundialFace({
    super.key,
    required this.elapsed,
    this.sessionMax = const Duration(hours: 3),
    this.annualGoalHours = 1000,
    // Required, no default: a default of 0 is how Flow shipped a Dual Ring
    // whose year ring never filled (visual-02).
    required this.yearTotal,
    this.style = FlowTimerStyle.gnomon,
    this.isRunning = false,
  });

  final Duration elapsed;
  final Duration sessionMax;
  final int annualGoalHours;

  /// Time outside so far this year, drawn by the Dual Ring's outer ring.
  final Duration yearTotal;
  final FlowTimerStyle style;
  final bool isRunning;

  @override
  State<SundialFace> createState() => _SundialFaceState();
}

class _SundialFaceState extends State<SundialFace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _sunScale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _sunScale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    if (widget.isRunning) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(SundialFace old) {
    super.didUpdateWidget(old);
    if (widget.isRunning == old.isRunning) return;
    if (widget.isRunning) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.animateTo(0, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _sunScale,
      builder: (context, _) {
        // The small print follows the reader's text size, capped at 2x so it
        // stays inside the dial.
        final captionScaler =
            MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 2.0);
        final painter = switch (widget.style) {
          FlowTimerStyle.gnomon => GnomonPainter(
              elapsed: widget.elapsed,
              maxDuration: widget.sessionMax,
              sweepColor: colors.primary,
              trackColor: colors.surfaceContainerHighest,
              sunColor: colors.primary,
              textColor: colors.onSurface,
              sunScale: _sunScale.value,
              captionScaler: captionScaler,
            ),
          FlowTimerStyle.arc => ArcPainter(
              elapsed: widget.elapsed,
              maxDuration: widget.sessionMax,
              sweepColor: colors.primary,
              trackColor: colors.surfaceContainerHighest,
              sunColor: colors.primary,
              textColor: colors.onSurface,
              sunScale: _sunScale.value,
              captionScaler: captionScaler,
            ),
          FlowTimerStyle.dualRing => DualRingPainter(
              elapsed: widget.elapsed,
              maxDuration: widget.sessionMax,
              annualGoalHours: widget.annualGoalHours,
              yearTotal: widget.yearTotal,
              sweepColor: colors.primary,
              trackColor: colors.surfaceContainerHighest,
              sunColor: colors.primary,
              textColor: colors.onSurface,
              sunScale: _sunScale.value,
              captionScaler: captionScaler,
            ),
        };
        final lap = sessionLap(widget.elapsed, widget.sessionMax);
        final h = widget.elapsed.inHours;
        final m = widget.elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
        final sec =
            widget.elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
        final hours = widget.sessionMax.inMinutes % 60 == 0
            ? '${widget.sessionMax.inHours} hours'
            : '${widget.sessionMax.inMinutes} minutes';
        return Semantics(
          label: 'Session $h:$m:$sec; one sweep of the dial is $hours'
              '${lap.lap > 1 ? ', on lap ${lap.lap}' : ''}',
          child: CustomPaint(painter: painter, size: Size.infinite),
        );
      },
    );
  }
}

// ─── Gnomon (half-circle, literal sundial) ─────────────────────────────────

class GnomonPainter extends CustomPainter {
  const GnomonPainter({
    required this.elapsed,
    required this.maxDuration,
    required this.sweepColor,
    required this.trackColor,
    required this.sunColor,
    required this.textColor,
    this.sunScale = 1.0,
    this.captionScaler = TextScaler.noScaling,
  });

  final Duration elapsed;
  final Duration maxDuration;

  /// The reader's text scale for the small print, capped at 2x.
  final TextScaler captionScaler;
  final Color sweepColor;
  final Color trackColor;
  final Color sunColor;
  final Color textColor;
  final double sunScale;

  @override
  void paint(Canvas canvas, Size size) {
    if (maxDuration == Duration.zero) return;
    final center = Offset(size.width / 2, size.height * 0.82);
    final radius = size.width * 0.42;
    final lap = sessionLap(elapsed, maxDuration);
    final progress = lap.progress;

    // Track; past the first lap, the finished lap shows faintly under it.
    _arc(canvas, center, radius, trackColor, math.pi, math.pi, 10);
    if (lap.lap > 1) {
      _arc(canvas, center, radius, sweepColor.withValues(alpha: 0.35),
          math.pi, math.pi, 10);
    }
    // Sweep
    if (progress > 0) {
      _arc(canvas, center, radius, sweepColor, math.pi, math.pi * progress, 10);
    }

    // Sun position
    final sunAngle = math.pi + math.pi * progress;
    final sunPos = Offset(
      center.dx + radius * math.cos(sunAngle),
      center.dy + radius * math.sin(sunAngle),
    );

    // Gnomon line
    canvas.drawLine(
      center,
      sunPos,
      Paint()
        ..color = textColor.withValues(alpha: 0.25)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // Sun glow when scaled up
    if (sunScale > 1.0) {
      canvas.drawCircle(
        sunPos,
        9 * sunScale * 1.6,
        Paint()..color = sunColor.withValues(alpha: 0.15 * (sunScale - 1.0) / 0.35),
      );
    }

    // Sun circle
    canvas.drawCircle(sunPos, 9 * sunScale, Paint()..color = sunColor);

    // Base line
    canvas.drawLine(
      Offset(center.dx - radius - 6, center.dy),
      Offset(center.dx + radius + 6, center.dy),
      Paint()
        ..color = trackColor
        ..strokeWidth = 1,
    );

    // Ticks
    _ticks(canvas, center, radius);

    // Elapsed text
    _drawText(canvas, center.translate(0, -30), _fmt(), 20, textColor);

    // The scale, stated: what a full sweep means (and the lap past it).
    _paintCaption(canvas, center.translate(0, 14),
        _scaleCaption(elapsed, maxDuration), textColor.withValues(alpha: 0.6),
        captionScaler,
        size.shortestSide * 0.6);
  }

  void _arc(Canvas c, Offset center, double r, Color color, double start,
      double sweep, double width) {
    c.drawArc(
      Rect.fromCircle(center: center, radius: r),
      start,
      sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  void _ticks(Canvas canvas, Offset center, double radius) {
    final milestones = [
      (15 * 60, '15m'),
      (30 * 60, '30m'),
      (60 * 60, '1h'),
      (120 * 60, '2h'),
      // The end of the sweep is labelled too: the scale is on the face.
      (maxDuration.inSeconds, _lapLength(maxDuration)),
    ];
    for (final (secs, label) in milestones) {
      final frac = secs / maxDuration.inSeconds;
      if (frac > 1) continue;
      final angle = math.pi + math.pi * frac;
      final inner = Offset(
        center.dx + (radius - 12) * math.cos(angle),
        center.dy + (radius - 12) * math.sin(angle),
      );
      final outer = Offset(
        center.dx + (radius + 4) * math.cos(angle),
        center.dy + (radius + 4) * math.sin(angle),
      );
      canvas.drawLine(inner, outer,
          Paint()
            ..color = textColor.withValues(alpha: 0.35)
            ..strokeWidth = 1.5);
      _drawText(
        canvas,
        Offset(center.dx + (radius + 16) * math.cos(angle),
            center.dy + (radius + 16) * math.sin(angle)),
        label,
        8,
        textColor.withValues(alpha: 0.4),
      );
    }
  }

  void _drawText(Canvas c, Offset pos, String text, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            color: color, fontSize: size, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, pos.translate(-tp.width / 2, -tp.height / 2));
  }

  String _fmt() {
    final h = elapsed.inHours;
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  bool shouldRepaint(GnomonPainter old) =>
      old.elapsed != elapsed ||
      old.captionScaler != captionScaler ||
      old.sunScale != sunScale ||
      old.sweepColor != sweepColor ||
      old.trackColor != trackColor;
}

// ─── Arc (full circle sweep) ────────────────────────────────────────────────

class ArcPainter extends CustomPainter {
  const ArcPainter({
    required this.elapsed,
    required this.maxDuration,
    required this.sweepColor,
    required this.trackColor,
    required this.sunColor,
    required this.textColor,
    this.sunScale = 1.0,
    this.captionScaler = TextScaler.noScaling,
  });

  final Duration elapsed;
  final Duration maxDuration;

  /// The reader's text scale for the small print, capped at 2x.
  final TextScaler captionScaler;
  final Color sweepColor;
  final Color trackColor;
  final Color sunColor;
  final Color textColor;
  final double sunScale;

  @override
  void paint(Canvas canvas, Size size) {
    if (maxDuration == Duration.zero) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    final lap = sessionLap(elapsed, maxDuration);
    final progress = lap.progress;

    // Track; past the first lap, the finished lap shows faintly under it.
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = lap.lap > 1 ? sweepColor.withValues(alpha: 0.35) : trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    // Sweep (from top, clockwise)
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = sweepColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }

    // Sun at leading edge
    final sunAngle = -math.pi / 2 + 2 * math.pi * progress;
    final sunPos = Offset(
      center.dx + radius * math.cos(sunAngle),
      center.dy + radius * math.sin(sunAngle),
    );

    if (sunScale > 1.0) {
      canvas.drawCircle(
        sunPos,
        9 * sunScale * 1.6,
        Paint()..color = sunColor.withValues(alpha: 0.15 * (sunScale - 1.0) / 0.35),
      );
    }
    canvas.drawCircle(sunPos, 9 * sunScale, Paint()..color = sunColor);

    // Tick marks
    final ticks = [15 * 60, 30 * 60, 60 * 60, 120 * 60];
    for (final secs in ticks) {
      final frac = secs / maxDuration.inSeconds;
      if (frac > 1) continue;
      final a = -math.pi / 2 + 2 * math.pi * frac;
      canvas.drawLine(
        Offset(center.dx + (radius - 10) * math.cos(a),
            center.dy + (radius - 10) * math.sin(a)),
        Offset(center.dx + (radius + 4) * math.cos(a),
            center.dy + (radius + 4) * math.sin(a)),
        Paint()
          ..color = textColor.withValues(alpha: 0.35)
          ..strokeWidth = 1.5,
      );
    }

    // Center time
    final tp = TextPainter(
      text: TextSpan(
        text: _fmt(),
        style: TextStyle(
            color: textColor, fontSize: 22, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center.translate(-tp.width / 2, -tp.height / 2));

    // The scale, stated: what a full sweep means (and the lap past it).
    _paintCaption(canvas, center.translate(0, tp.height / 2 + 10),
        _scaleCaption(elapsed, maxDuration), textColor.withValues(alpha: 0.6),
        captionScaler,
        size.shortestSide * 0.6);
  }

  String _fmt() {
    final h = elapsed.inHours;
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  bool shouldRepaint(ArcPainter old) =>
      old.elapsed != elapsed ||
      old.captionScaler != captionScaler ||
      old.sunScale != sunScale ||
      old.sweepColor != sweepColor ||
      old.trackColor != trackColor;
}

// ─── Dual Ring (outer = annual goal, inner = session) ──────────────────────

class DualRingPainter extends CustomPainter {
  const DualRingPainter({
    required this.elapsed,
    required this.maxDuration,
    required this.annualGoalHours,
    required this.yearTotal,
    required this.sweepColor,
    required this.trackColor,
    required this.sunColor,
    required this.textColor,
    this.sunScale = 1.0,
    this.captionScaler = TextScaler.noScaling,
  });

  final Duration elapsed;
  final Duration maxDuration;

  /// The reader's text scale for the small print, capped at 2x.
  final TextScaler captionScaler;
  final int annualGoalHours;
  final Duration yearTotal;
  final Color sweepColor;
  final Color trackColor;
  final Color sunColor;
  final Color textColor;
  final double sunScale;

  @override
  void paint(Canvas canvas, Size size) {
    if (maxDuration == Duration.zero || annualGoalHours == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width * 0.46;
    final innerR = size.width * 0.32;

    final yearProgress =
        (yearTotal.inSeconds / (annualGoalHours * 3600)).clamp(0.0, 1.0);
    final lap = sessionLap(elapsed, maxDuration);
    final sessionProgress = lap.progress;

    // Outer ring (annual)
    _ring(canvas, center, outerR, trackColor, 0, 2 * math.pi, 6);
    if (yearProgress > 0) {
      _ring(canvas, center, outerR, sweepColor.withValues(alpha: 0.5),
          -math.pi / 2, 2 * math.pi * yearProgress, 6);
    }

    // Inner ring (session); past the first lap the finished lap shows
    // faintly under the current one.
    _ring(canvas, center, innerR,
        lap.lap > 1 ? sweepColor.withValues(alpha: 0.35) : trackColor,
        0, 2 * math.pi, 10);
    if (sessionProgress > 0) {
      _ring(canvas, center, innerR, sweepColor,
          -math.pi / 2, 2 * math.pi * sessionProgress, 10);
    }

    // Sun on inner ring
    final sunAngle = -math.pi / 2 + 2 * math.pi * sessionProgress;
    final sunPos = Offset(
      center.dx + innerR * math.cos(sunAngle),
      center.dy + innerR * math.sin(sunAngle),
    );

    if (sunScale > 1.0) {
      canvas.drawCircle(
        sunPos,
        8 * sunScale * 1.6,
        Paint()..color = sunColor.withValues(alpha: 0.15 * (sunScale - 1.0) / 0.35),
      );
    }
    canvas.drawCircle(sunPos, 8 * sunScale, Paint()..color = sunColor);

    // Center: session elapsed
    final tp = TextPainter(
      text: TextSpan(
        text: _fmtSession(),
        style: TextStyle(
            color: textColor, fontSize: 20, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center.translate(-tp.width / 2, -tp.height / 2 - 8));

    // Sub-center: year total
    final yearTp = TextPainter(
      text: TextSpan(
        text: '${yearTotal.toHoursLabel()} / ${annualGoalHours}h',
        style:
            TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    yearTp.paint(
        canvas, center.translate(-yearTp.width / 2, tp.height / 2 + 2));

    // The scale, stated: what a full sweep of the inner ring means.
    _paintCaption(
        canvas,
        center.translate(0, tp.height / 2 + yearTp.height + 12),
        _scaleCaption(elapsed, maxDuration),
        textColor.withValues(alpha: 0.6),
        captionScaler,
        size.shortestSide * 0.6);
  }

  void _ring(Canvas c, Offset center, double r, Color color, double start,
      double sweep, double width) {
    c.drawArc(
      Rect.fromCircle(center: center, radius: r),
      start,
      sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  String _fmtSession() {
    final h = elapsed.inHours;
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  bool shouldRepaint(DualRingPainter old) =>
      old.elapsed != elapsed ||
      old.captionScaler != captionScaler ||
      old.sunScale != sunScale ||
      old.yearTotal != yearTotal ||
      old.annualGoalHours != annualGoalHours ||
      old.sweepColor != sweepColor ||
      old.trackColor != trackColor;
}
