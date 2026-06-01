// lib/features/badges/presentation/badge_shelf.dart
import 'package:flutter/material.dart' hide Badge;
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart' hide UserPrefs;
import 'package:sundial/shared/theme/app_spacing.dart';

class BadgeShelf extends ConsumerWidget {
  const BadgeShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(badgesRepositoryProvider).watchAllBadges();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Badges',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<List<Badge>>(
          stream: stream,
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            final badges = snap.data!;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: badges.map((b) => _BadgeChip(badge: b)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});
  final Badge badge;

  @override
  Widget build(BuildContext context) {
    final earned = badge.earnedAt != null;
    final unearned = Theme.of(context).colorScheme.onSurfaceVariant;
    return Chip(
      avatar: Icon(
        LucideIcons.sun,
        color: earned
            ? const Color(0xFFF5A623)
            : unearned.withValues(alpha: 0.3),
      ),
      label: Text('${badge.thresholdHours}h'),
      backgroundColor: earned
          ? const Color(0xFFF5A623).withValues(alpha: 0.1)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}
