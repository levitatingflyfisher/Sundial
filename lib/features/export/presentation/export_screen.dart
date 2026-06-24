import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sundial/core/providers/core_providers.dart';
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
          const Divider(height: AppSpacing.xl),
          // ── Export ──────────────────────────────────────────────────
          _ExportTile(
            icon: LucideIcons.fileText,
            title: 'Plaintext (.sundial)',
            subtitle: 'Human-readable summary (export only)',
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
            subtitle: 'Machine-readable backup',
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
            subtitle: const Text('Printable summary'),
            trailing: IconButton(
              icon: const Icon(LucideIcons.share2),
              tooltip: 'Share',
              onPressed: () => _exportPdf(context, ref),
            ),
          ),
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
