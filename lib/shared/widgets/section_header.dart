// lib/shared/widgets/section_header.dart
import 'package:flutter/material.dart';
import 'package:sundial/shared/theme/app_spacing.dart';

/// A small all-caps heading that sits with the rows it introduces (tight
/// below, generous above). Used by Settings and Backup & Restore so both name
/// their areas the same way.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        top: AppSpacing.lg,
        bottom: AppSpacing.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
        ),
      ),
    );
  }
}
