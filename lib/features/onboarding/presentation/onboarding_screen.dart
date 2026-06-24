// lib/features/onboarding/presentation/onboarding_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
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
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() => _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );

  Future<void> _select(AppMode mode) async {
    await ref.read(settingsRepositoryProvider).setAppMode(mode);
    if (mounted) context.go('/timer');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _WelcomePage(onNext: _next),
          _ModePage(onSelect: _select),
        ],
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
              'Track outdoor time with your family.\nNo ads, no account, no cloud — just time well spent.',
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

// ── Page 2: Mode selection ───────────────────────────────────────────────────

class _ModePage extends StatelessWidget {
  const _ModePage({required this.onSelect});
  final Future<void> Function(AppMode) onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Text(
              'How do you want to start\nusing Sundial?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Switch between Flow and Rich any time — one tap.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _ModeCard(
              title: 'Flow',
              subtitle: 'Timer + yearly total. Nothing else.',
              isRecommended: true,
              onTap: () => onSelect(AppMode.flow),
            ),
            const SizedBox(height: AppSpacing.md),
            _ModeCard(
              title: 'Rich',
              subtitle: 'History, stats, badges, goals, notes.',
              isRecommended: false,
              onTap: () => onSelect(AppMode.rich),
            ),
            const Spacer(),
            Text(
              'Both free, forever. Your data is always the same — just a different view.',
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

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.isRecommended,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final bool isRecommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(
            color: isRecommended ? cs.primary : cs.outline,
            width: isRecommended ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isRecommended ? cs.primary.withValues(alpha: 0.06) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    )),
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
    final sunAngle = math.pi + math.pi * 0.5;
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
