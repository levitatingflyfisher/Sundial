// lib/features/profiles/presentation/profiles_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/shared/theme/app_colors.dart';
import 'package:sundial/shared/theme/app_spacing.dart';

final profileColors = [
  AppColors.sage500.toARGB32(), // sage green (brand, canonical)
  0xFFD48B44, // warm amber
  0xFFBE6B5E, // terracotta
  0xFF5B8DB8, // sky blue
  0xFF8B7BB5, // lavender
  0xFF3D7A5E, // forest green
  0xFFC9A84C, // warm gold
  0xFFB56B8E, // rose
];

class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key});

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  // Removing a person is a deliberate tap, so it does not ask; it offers an
  // Undo that never times out (fleet delete ruling). The offer lasts until
  // the person acts, removes someone else, or leaves this screen.
  final _undo = OhUndoController();

  @override
  void dispose() {
    _undo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      body: OhPage(
        padding: EdgeInsets.zero,
        child: profilesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => OhErrorState.fromError(
            e,
            stackTrace: st,
            title: "People didn’t load",
            onRetry: () => ref.invalidate(profilesListProvider),
          ),
          data: (profiles) => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: profiles.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = profiles[i];
              final canDelete = profiles.length > 1;
              return ListTile(
                leading: _ProfileAvatar(profile: p, size: 36),
                title: Text(p.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.pencil, size: 18),
                      tooltip: 'Edit ${p.name}',
                      onPressed: () => _showEditSheet(context, ref, p),
                    ),
                    if (canDelete)
                      IconButton(
                        icon: Icon(LucideIcons.trash2,
                            size: 18,
                            color: Theme.of(context).colorScheme.error),
                        tooltip: 'Remove ${p.name}',
                        onPressed: () => _remove(p),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: OhUndoBar(controller: _undo),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditSheet(context, ref, null),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  Future<void> _showEditSheet(
      BuildContext context, WidgetRef ref, Profile? existing) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ProfileEditSheet(existing: existing),
    );
  }

  Future<void> _remove(Profile p) async {
    final repo = ref.read(profilesRepositoryProvider);
    final wasActive = ref.read(activeProfileIdProvider) == p.id;
    final deleted = await repo.deleteProfile(p.id);
    if (deleted == null) return;
    // If deleted profile was active, fall back to Everyone (the sentinel
    // that never gets deleted — 'default' is just another user profile).
    if (wasActive) {
      ref.read(activeProfileIdProvider.notifier).select(kEveryoneProfileId);
    }
    _undo.show(
      message: 'Removed ${p.name}. Their sessions stay in history.',
      onUndo: () async {
        await repo.restoreProfile(deleted);
        if (wasActive) {
          ref.read(activeProfileIdProvider.notifier).select(p.id);
        }
      },
    );
  }
}

class _ProfileEditSheet extends ConsumerStatefulWidget {
  const _ProfileEditSheet({this.existing});
  final Profile? existing;

  @override
  ConsumerState<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<_ProfileEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emojiCtrl;
  late int _color;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _emojiCtrl = TextEditingController(text: widget.existing?.emoji ?? '');
    _color = widget.existing?.colorValue ?? profileColors.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emojiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isNew = widget.existing == null;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
          AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isNew ? 'Add person' : 'Edit person',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Mom, Liam, Zoe…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _emojiCtrl,
            decoration: const InputDecoration(
              labelText: 'Emoji (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Color', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            children: profileColors.map((c) {
              final selected = c == _color;
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: cs.onSurface, width: 2.5)
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: _save,
                child: Text(isNew ? 'Add' : 'Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final emoji =
        _emojiCtrl.text.trim().isEmpty ? null : _emojiCtrl.text.trim();
    final repo = ref.read(profilesRepositoryProvider);
    if (widget.existing == null) {
      await repo.createProfile(name: name, emoji: emoji, colorValue: _color);
    } else {
      await repo.updateProfile(
        id: widget.existing!.id,
        name: name,
        emoji: emoji,
        colorValue: _color,
      );
    }
    if (mounted) Navigator.pop(context);
  }
}

/// Reusable avatar: shows emoji if set, otherwise first letter in a colored circle.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile, this.size = 28});
  final Profile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(profile.colorValue),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        profile.emoji?.isNotEmpty == true
            ? profile.emoji!
            : profile.name.substring(0, 1).toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.45,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Public-facing avatar widget used by timer/flow screens.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.profile, this.size = 28});
  final Profile profile;
  final double size;

  @override
  Widget build(BuildContext context) =>
      _ProfileAvatar(profile: profile, size: size);
}
