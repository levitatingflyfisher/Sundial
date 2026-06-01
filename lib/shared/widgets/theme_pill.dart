// lib/shared/widgets/theme_pill.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sundial/core/providers/core_providers.dart';

class ThemePill extends ConsumerWidget {
  const ThemePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark =
        ref.watch(userPrefsProvider).valueOrNull?.isDarkMode ?? false;
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            icon: LucideIcons.sun,
            isSelected: !isDark,
            onTap: () =>
                ref.read(settingsRepositoryProvider).setDarkMode(false),
          ),
          _Segment(
            icon: LucideIcons.moon,
            isSelected: isDark,
            onTap: () =>
                ref.read(settingsRepositoryProvider).setDarkMode(true),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
