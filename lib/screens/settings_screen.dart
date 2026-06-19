import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/batch_controller.dart';
import '../services/backup_service.dart';

/// Import/export and maintenance actions.
///
/// This screen intentionally avoids file-picker plugins. Local backups are kept
/// in SharedPreferences, while text export/import remains as a plugin-free
/// escape hatch for moving data between devices.
class SettingsScreen extends StatelessWidget {
  static const _localBackupKey = 'brewer_diary_local_backups_v1';
  static const _maxLocalBackups = 10;

  final BatchController controller;
  SettingsScreen({super.key, required this.controller});

  final BackupService _backupService = BackupService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beállítások')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: () => _createLocalBackup(context),
            icon: const Icon(Icons.save),
            label: const Text('Helyi backup mentése'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _restoreLocalBackup(context),
            icon: const Icon(Icons.restore),
            label: const Text('Helyi backup visszaállítása'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showBackupExport(context),
            icon: const Icon(Icons.article_outlined),
            label: const Text('Backup export szövegként'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showBackupImport(context),
            icon: const Icon(Icons.input),
            label: const Text('Backup import szövegből'),
          ),
          const Divider(height: 32),
          FilledButton.icon(
            onPressed: () => _loadSeed(context),
            icon: const Icon(Icons.inventory),
            label: const Text('Alap adatok betöltése'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showRawExport(context),
            icon: const Icon(Icons.upload),
            label: const Text('Régi JSON export'),
          ),
        ],
      ),
    );
  }

  Future<void> _createLocalBackup(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backups = prefs.getStringList(_localBackupKey) ?? [];
      final backupText = _backupService.buildBackupJson(controller.exportJson());

      backups.insert(0, backupText);
      final trimmed = backups.take(_maxLocalBackups).toList();
      await prefs.setStringList(_localBackupKey, trimmed);

      if (context.mounted) {
        _snack(context, 'Helyi backup elmentve. Megőrzött mentések: ${trimmed.length}.');
      }
    } catch (error) {
      if (context.mounted) _snack(context, 'Helyi backup mentés sikertelen: $error');
    }
  }

  Future<void> _restoreLocalBackup(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final backups = prefs.getStringList(_localBackupKey) ?? [];

    if (!context.mounted) return;
    if (backups.isEmpty) {
      _snack(context, 'Még nincs helyi backup.');
      return;
    }

    final selected = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Helyi backup visszaállítása'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: backups.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final backup = backups[index];
              return ListTile(
                title: Text(_backupService.describeBackup(backup)),
                subtitle: Text('${index + 1}. helyi mentés'),
                onTap: () => Navigator.pop(context, backup),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse'))],
      ),
    );

    if (selected == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Biztos visszaállítod?'),
        content: const Text('Ez lecseréli a jelenlegi helyi adatokat a kiválasztott backup tartalmára.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Mégse')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Visszaállítás')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final batchesJson = _backupService.extractBatchesJson(selected);
      await controller.importJson(batchesJson);
      if (context.mounted) _snack(context, 'Helyi backup visszaállítva.');
    } catch (error) {
      if (context.mounted) _snack(context, 'Visszaállítás sikertelen: $error');
    }
  }

  void _showBackupExport(BuildContext context) {
    final backupText = _backupService.buildBackupJson(controller.exportJson());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Backup export szövegként'),
        content: SingleChildScrollView(child: SelectableText(backupText)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _showBackupImport(BuildContext context) {
    final text = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Backup import szövegből'),
        content: TextField(
          controller: text,
          maxLines: 10,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Illeszd be a Brewer Diary backup szöveget',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          FilledButton(
            onPressed: () async {
              try {
                final batchesJson = _backupService.extractBatchesJson(text.text);
                await controller.importJson(batchesJson);
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) _snack(context, 'Backup importálva.');
              } catch (error) {
                if (context.mounted) _snack(context, 'Backup import sikertelen: $error');
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSeed(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alap adatok betöltése'),
        content: const Text(
          'Ez lecseréli a jelenlegi helyi adatokat a beépített táblázat-importtal. Mehet?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Mégse')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Betöltés')),
        ],
      ),
    );

    if (confirmed != true) return;

    final jsonText = await rootBundle.loadString('seed/brewer_diary_seed.json');
    await controller.importJson(jsonText);

    if (context.mounted) _snack(context, 'Alap adatok betöltve.');
  }

  void _showRawExport(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Régi JSON export'),
        content: SingleChildScrollView(child: SelectableText(controller.exportJson())),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
