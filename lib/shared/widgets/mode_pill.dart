// lib/shared/widgets/mode_pill.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/features/settings/domain/user_prefs.dart';

class ModePill extends ConsumerWidget {
  const ModePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeAsync = ref.watch(appModeProvider);
    final widgetOverride = ref.watch(widgetLaunchOverrideProvider);
    final persistedMode = modeAsync.valueOrNull ?? AppMode.flow;
    // When widget-launch override is active, display shows Flow regardless
    // of persisted preference.
    final effectiveMode = widgetOverride ? AppMode.flow : persistedMode;
    final colorScheme = Theme.of(context).colorScheme;

    void switchTo(AppMode target) {
      if (target == AppMode.rich) {
        ref.read(settingsRepositoryProvider).setAppMode(AppMode.rich);
        ref.read(widgetLaunchOverrideProvider.notifier).state = false;
        context.go('/timer');
      } else {
        ref.read(settingsRepositoryProvider).setAppMode(AppMode.flow);
      }
    }

    // Tapping either side toggles to the other mode.
    final other = effectiveMode == AppMode.flow ? AppMode.rich : AppMode.flow;

    return GestureDetector(
      onTap: () => switchTo(other),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PillSegment(
              label: 'Flow',
              isSelected: effectiveMode == AppMode.flow,
            ),
            _PillSegment(
              label: 'Rich',
              isSelected: effectiveMode == AppMode.rich,
            ),
          ],
        ),
      ),
    );
  }
}

class _PillSegment extends StatelessWidget {
  const _PillSegment({
    required this.label,
    required this.isSelected,
  });
  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
