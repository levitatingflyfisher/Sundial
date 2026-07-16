import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sundial/core/providers/core_providers.dart';
import 'package:sundial/features/export/data/backup_file_save.dart';
import 'package:sundial/features/export/data/json_export_impl.dart';
import 'package:sundial/features/export/data/json_import_impl.dart';
import 'package:sundial/features/export/data/pdf_export_impl.dart';
import 'package:sundial/features/export/data/plaintext_export_impl.dart';
import 'package:sundial/shared/theme/app_spacing.dart';

class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Import ──────────────────────────────────────────────────
          ListTile(
            leading: const Icon(LucideIcons.folderOpen),
            title: const Text('Import from JSON'),
            subtitle: const Text('Restore sessions from a backup file'),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () => _importJson(context, ref),
          ),
          ListTile(
            leading: const Icon(LucideIcons.lockKeyhole),
            title: const Text('Restore from encrypted backup'),
            subtitle: const Text('Load data from an .ohbk file'),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () => _restoreEncrypted(context, ref),
          ),
          const Divider(height: AppSpacing.xl),
          // ── Export ──────────────────────────────────────────────────
          // F14: labelled "unencrypted" now that the encrypted backup
          // section below offers a protected alternative — the security
          // distinction was previously stated on only one side.
          _ExportTile(
            icon: LucideIcons.fileText,
            title: 'Plaintext (.sundial)',
            subtitle: 'Unencrypted, human-readable summary (export only)',
            onSave: () => _buildPlaintext(ref).then(
              (r) => _saveLocally(context, r.$1, r.$2),
            ),
            onShare: () => _buildPlaintext(ref).then(
              (r) => _shareFile(context, r.$1, r.$2),
            ),
          ),
          _ExportTile(
            icon: LucideIcons.braces,
            title: 'JSON',
            subtitle: 'Unencrypted, machine-readable backup',
            onSave: () => _buildJson(ref).then(
              (r) => _saveLocally(context, r.$1, r.$2),
            ),
            onShare: () => _buildJson(ref).then(
              (r) => _shareFile(context, r.$1, r.$2),
            ),
          ),
          ListTile(
            leading: const Icon(LucideIcons.file),
            title: const Text('PDF'),
            subtitle: const Text('Unencrypted, printable summary'),
            trailing: IconButton(
              icon: const Icon(LucideIcons.share2),
              tooltip: 'Share',
              onPressed: () => _exportPdf(context, ref),
            ),
          ),
          const Divider(height: AppSpacing.xl),
          // ── Encrypted backup (.ohbk) ───────────────────────────────
          const _EncryptedBackupSection(),
        ],
      ),
    );
  }

  // ── Builders ─────────────────────────────────────────────────────

  Future<(String content, String filename)> _buildPlaintext(WidgetRef ref) async {
    final sessions =
        await ref.read(sessionsRepositoryProvider).watchAllSessions().first;
    final prefs = await ref.read(settingsRepositoryProvider).getUserPrefs();
    final content = PlaintextExporter()
        .buildFile(sessions, annualGoalHours: prefs.annualGoalHours);
    return (content, 'sundial-backup.sundial');
  }

  Future<(String content, String filename)> _buildJson(WidgetRef ref) async {
    final sessions =
        await ref.read(sessionsRepositoryProvider).watchAllSessions().first;
    final profiles =
        await ref.read(profilesRepositoryProvider).watchAll().first;
    final badges =
        await ref.read(badgesRepositoryProvider).watchAllBadges().first;
    final prefs = await ref.read(settingsRepositoryProvider).getUserPrefs();
    final content = JsonExporter().buildJson(
      sessions,
      annualGoalHours: prefs.annualGoalHours,
      profiles: profiles,
      badges: badges,
    );
    return (content, 'sundial-backup.json');
  }

  // ── Save / Share ──────────────────────────────────────────────────

  Future<void> _saveLocally(
      BuildContext context, String content, String filename) async {
    try {
      Directory? dir;
      try {
        dir = await getExternalStorageDirectory();
      } catch (_) {}
      dir ??= await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(content);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to ${file.path}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _shareFile(
      BuildContext context, String content, String filename) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], text: 'Sundial backup');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    try {
      final sessions =
          await ref.read(sessionsRepositoryProvider).watchAllSessions().first;
      final prefs = await ref.read(settingsRepositoryProvider).getUserPrefs();
      await PdfExporter()
          .sharePdf(sessions, annualGoalHours: prefs.annualGoalHours);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  // ── Import ────────────────────────────────────────────────────────

  Future<void> _importJson(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;
    try {
      final content = await File(result.files.single.path!).readAsString();
      final payload = JsonImporter().parse(content);
      final profilesRepo = ref.read(profilesRepositoryProvider);
      // Restore profiles first so FKs resolve.
      for (final p in payload.profiles) {
        await profilesRepo.upsertRaw(p);
      }
      final repo = ref.read(sessionsRepositoryProvider);
      int imported = 0;
      for (final session in payload.sessions) {
        final r = await repo.saveSession(session);
        if (r.isRight()) imported++;
      }
      // Restore earned badges last, after sessions exist, so hour totals are
      // consistent for any downstream revoke-if-below checks.
      if (payload.earnedBadges.isNotEmpty) {
        await ref
            .read(badgesRepositoryProvider)
            .restoreEarnedBadges(payload.earnedBadges);
      }
      // F10: the same annual-goal drop as the encrypted-backup restore path
      // — a plain JSON backup carries the goal too, and it must be applied
      // rather than silently discarded.
      if (payload.annualGoalHours != null) {
        await ref
            .read(settingsRepositoryProvider)
            .setAnnualGoalHours(payload.annualGoalHours!);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported $imported sessions, ${payload.profiles.length} profiles, '
              '${payload.earnedBadges.length} badges',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  // ── Encrypted restore (.ohbk) ───────────────────────────────────────
  //
  // Delegates the whole file-pick → destructive-confirm → wrong-phrase
  // fallback → outcome-message flow to sanctuary_backup_ui's [BackupFlow]
  // rather than re-copying that ~50-line state machine here — only the
  // presentation (Sundial's own tiles/icons instead of a generic settings
  // section) is app-specific, per SANCTUARY-BRIEF §4.W2.
  Future<void> _restoreEncrypted(BuildContext context, WidgetRef ref) =>
      const BackupFlow().runRestore(context, ref);
}

// ── Encrypted backup (.ohbk) section — setup card + export tile ────────
//
// Lives on the export screen itself (SANCTUARY-BRIEF §4.W2 app-specific
// block: "not as a separate settings section"). Uses the same seed-phrase
// widgets and BackupController as every other sanctuary app; only the
// layout matches Sundial's existing ListTile/_ExportTile conventions instead
// of the generic BackupSettingsSection.
class _EncryptedBackupSection extends ConsumerWidget {
  const _EncryptedBackupSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);

    return authAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (authState) => Column(children: [
        _stateTile(context, ref, authState),
        // The snapshot vault (BACKUP_RETENTION_SPEC §2.A) — reachable in
        // every auth state: exports and restores populate it regardless.
        ListTile(
          leading: const Icon(LucideIcons.history),
          title: const Text('Previous backups'),
          subtitle:
              const Text('Snapshots kept on this device — restore or pin'),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => showBackupVaultSheet(context),
        ),
      ]),
    );
  }

  Widget _stateTile(BuildContext context, WidgetRef ref, AuthState authState) {
    final hasKey = authState.masterEncryptionKey != null;
    final seedAcked = authState.seedAcknowledged;

    if (!hasKey) {
      return ListTile(
        leading: const Icon(LucideIcons.keyRound),
        title: const Text('Set up encrypted backup'),
        subtitle:
            const Text('Generate 12 recovery words to encrypt your backup'),
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: () => _setup(context, ref),
      );
    }

    if (!seedAcked) {
      return ListTile(
        leading: const Icon(LucideIcons.penLine),
        title: const Text('Complete backup setup'),
        subtitle: const Text('Re-enter your recovery words to finish setup'),
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: () => _confirmReEntry(context, ref),
      );
    }

    return ListTile(
          leading: const Icon(LucideIcons.shieldCheck),
          title: const Text('Encrypted backup (.ohbk)'),
          subtitle: authState.lastBackupAt != null
              ? Text('Last backup: ${_formatDate(authState.lastBackupAt!)}')
              : const Text(
                  'Save an encrypted copy of your sessions, profiles, and badges'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // F15: dart:io file writes aren't available on web — hide
              // Save there rather than offer an affordance that always
              // fails; Share (bytes-only, web-safe) remains available.
              if (backupSaveToDeviceSupported)
                IconButton(
                  icon: const Icon(LucideIcons.download, size: 20),
                  tooltip: 'Save to device',
                  onPressed: () => _saveToDevice(context, ref),
                ),
              IconButton(
                icon: const Icon(LucideIcons.share2, size: 20),
                tooltip: 'Share',
                // Share goes through BackupFlow's tested export orchestration
                // verbatim — only the "Save to device" branch is app-specific.
                onPressed: () => const BackupFlow().runExport(context, ref),
              ),
            ],
          ),
        );
  }

  // Both the seed-generate/show/re-entry-confirm flow and the wrong-words
  // retry loop are BackupFlow's tested orchestration verbatim — only the
  // trigger (Sundial's own ListTiles, not BackupSettingsSection) is
  // app-specific, per SANCTUARY-BRIEF §4.W2.
  Future<void> _setup(BuildContext context, WidgetRef ref) =>
      const BackupFlow().runSeedSetup(context, ref);

  Future<void> _confirmReEntry(BuildContext context, WidgetRef ref) =>
      const BackupFlow().confirmPhraseReEntry(context, ref);

  // F15: the on-device write is confined to the io/web split
  // (backup_file_save.dart) so an unconditional dart:io File write is never
  // reachable on the web target — the Save icon is hidden there instead
  // (see `backupSaveToDeviceSupported` in build() above). Not part of
  // BackupFlow (which is Share-only, by design, to stay web-safe), so this
  // one branch stays app-specific.
  Future<void> _saveToDevice(BuildContext context, WidgetRef ref) async {
    final result =
        await ref.read(backupControllerProvider.notifier).exportBackup();
    if (result == null || !context.mounted) return;

    try {
      final path =
          await saveBackupBytesToDevice(result.bytes, result.filename);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to $path'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(backupSaveErrorMessage(e))),
        );
      }
    }
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}

/// Maps a "Save to device" failure for the encrypted backup to calm,
/// specific copy — never the raw exception text (F11). Mirrors the
/// RestoreOutcome-mapped-message convention used elsewhere on this screen
/// rather than interpolating `$e` (which can leak a filesystem path or a
/// raw platform-exception message into the SnackBar).
@visibleForTesting
String backupSaveErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('Permission') || text.contains('permission')) {
    return "Couldn't save — storage permission was denied. Try Share instead.";
  }
  if (text.contains('MissingPluginException')) {
    return "Saving to device isn't available here. Try Share instead.";
  }
  return "Couldn't save the backup to this device. Try Share instead.";
}

// ── Export tile with Save + Share buttons ──────────────────────────

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onSave,
    required this.onShare,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.download, size: 20),
            tooltip: 'Save to device',
            onPressed: onSave,
          ),
          IconButton(
            icon: const Icon(LucideIcons.share2, size: 20),
            tooltip: 'Share',
            onPressed: onShare,
          ),
        ],
      ),
    );
  }
}
