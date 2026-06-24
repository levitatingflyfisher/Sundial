// lib/features/sessions/presentation/session_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/profiles/presentation/profiles_screen.dart'
    show ProfileAvatar;
import 'package:sundial/shared/extensions/duration_ext.dart';
import 'package:sundial/shared/widgets/confirm_dialog.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    required this.onTap,
    required this.onDelete,
    this.showEveryoneTag = false,
    this.profile,
  });
  final Session session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  /// When true, a null-profile session shows a subtle "Everyone" chip so it's
  /// distinguishable from sessions exclusive to the current profile filter.
  final bool showEveryoneTag;

  /// The owning profile for this session, if any. When non-null, a small
  /// colored dot (or emoji) is rendered next to the duration so that, in the
  /// Everyone view, it's clear which household member the session belongs to.
  /// Callers should only set this when 2+ profiles exist — solo users should
  /// not see a redundant dot on every session.
  final Profile? profile;

  static final _dateFmt = DateFormat('EEE, MMM d');

  @override
  Widget build(BuildContext context) {
    final dur = Duration(seconds: session.durationSecs);
    final date = DateTime.fromMillisecondsSinceEpoch(session.startTime);
    final cs = Theme.of(context).colorScheme;
    final isEveryone = session.profileId == null;

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: cs.error,
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      confirmDismiss: (_) => showConfirmDialog(
        context,
        title: 'Delete session?',
        message: 'This cannot be undone.',
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        onTap: onTap,
        title: Row(
          children: [
            if (profile != null) ...[
              ProfileAvatar(profile: profile!, size: 14),
              const SizedBox(width: 6),
            ],
            Text(
              dur.toHoursLabel(),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (showEveryoneTag && isEveryone) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.users,
                        size: 12, color: cs.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text(
                      'Everyone',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_dateFmt.format(date)),
            if (session.notes != null)
              Text(
                session.notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: const Icon(LucideIcons.chevronRight),
      ),
    );
  }
}
