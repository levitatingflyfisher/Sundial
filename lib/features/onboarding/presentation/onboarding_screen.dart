// lib/features/onboarding/presentation/onboarding_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';
import 'package:sundial/shared/theme/app_spacing.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  /// Flow is the default (ruling Q-D1): Get started opens straight into
  /// the timer, and Rich is offered later, from Flow, once there is a
  /// session to look back on. Storing the mode is also what lets the
  /// router out of onboarding.
  Future<void> _start() async {
    await ref.read(settingsRepositoryProvider).setAppMode(AppMode.flow);
    if (mounted) context.go('/timer');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OhPage(
        padding: EdgeInsets.zero,
        child: _WelcomePage(onNext: _start),
      ),
    );
  }
}

// ── Page 1: Welcome ──────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 2),
            Center(
              child: SizedBox(
                width: 160,
                height: 136,
                child: CustomPaint(
                    painter: _SundialIconPainter(color: cs.primary)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '1000 hours.\nOne tap at a time.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Track outdoor time with your family.\nNo ads, no account, no cloud. Just time well spent.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const Spacer(flex: 3),
            FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Get started'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Free forever. Your data never leaves your phone.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ── Mini sundial painter for welcome page ────────────────────────────────────

class _SundialIconPainter extends CustomPainter {
  const _SundialIconPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.82;
    final r = size.width * 0.42;

    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweepPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Full track arc
    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);
    // Sweep at 50%
    canvas.drawArc(rect, math.pi, math.pi * 0.5, false, sweepPaint);

    // Base line
    canvas.drawLine(
      Offset(cx - r - 4, cy),
      Offset(cx + r + 4, cy),
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..strokeWidth = 2,
    );

    // Sun position at 50% (angle = π + π*0.5 = 3π/2 = straight up)
    const sunAngle = math.pi + math.pi * 0.5;
    final sunPos = Offset(
      cx + r * math.cos(sunAngle),
      cy + r * math.sin(sunAngle),
    );

    // Gnomon line
    canvas.drawLine(
      Offset(cx, cy),
      sunPos,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 2,
    );

    // Sun dot
    canvas.drawCircle(sunPos, 7, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SundialIconPainter old) => old.color != color;
}
