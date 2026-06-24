// lib/shared/widgets/profile_chip_row.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/profiles/presentation/profiles_screen.dart';
import 'package:sundial/features/timer/domain/timer_state.dart';
import 'package:sundial/features/timer/presentation/timer_notifier.dart';

/// Shows a row of profile chips only when 2+ profiles exist.
/// Tapping a chip selects it as the active profile.
class ProfileChipRow extends ConsumerWidget {
  const ProfileChipRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesListProvider);
    return profilesAsync.when(
      data: (profiles) {
        if (profiles.length < 2) return const SizedBox.shrink();
        return _ProfileChips(profiles: profiles);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ProfileChips extends ConsumerWidget {
  const _ProfileChips({required this.profiles});
  final List<Profile> profiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeProfileIdProvider);
    final timerState = ref.watch(timerNotifierProvider);

    // Which profile does the running timer belong to?
    final runningProfileId = switch (timerState) {
      TimerRunning(:final profileId) => profileId,
      TimerPaused(:final profileId) => profileId,
      _ => null,
    };

    final cs = Theme.of(context).colorScheme;

    Widget buildChip({
      required String id,
      required Widget leading,
      required String label,
      required bool isActive,
      required bool isRunning,
      required Color activeColor,
    }) {
      return GestureDetector(
        onTap: () => ref.read(activeProfileIdProvider.notifier).select(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.18)
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: isActive ? Border.all(color: activeColor, width: 1.5) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              leading,
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: isActive ? FontWeight.w700 : null,
                      color: isActive ? activeColor : null,
                    ),
              ),
              if (isRunning)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final everyoneChip = buildChip(
      id: kEveryoneProfileId,
      leading: Icon(LucideIcons.users,
          size: 14,
          color: activeId == kEveryoneProfileId
              ? cs.primary
              : cs.onSurfaceVariant),
      label: 'Everyone',
      isActive: activeId == kEveryoneProfileId,
      isRunning: runningProfileId == kEveryoneProfileId,
      activeColor: cs.primary,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        spacing: 8,
        children: [
          everyoneChip,
          ...profiles.map((p) => buildChip(
                id: p.id,
                leading: ProfileAvatar(profile: p, size: 20),
                label: p.name,
                isActive: p.id == activeId,
                isRunning: p.id == runningProfileId,
                activeColor: Color(p.colorValue),
              )),
        ],
      ),
    );
  }
}
