import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../controllers/batch_controller.dart';
import '../services/backup_service.dart';

/// Import/export and maintenance actions.
///
/// The seed import is bundled as an asset so the initial spreadsheet data does
/// not need to be pasted into a tiny textbox.
class SettingsScreen extends StatelessWidget {
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
            onPressed: () => _createBackupFile(context),
            icon: const Icon(Icons.save_alt),
            label: const Text('Backup mentése fájlba'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _restoreBackupFile(context),
            icon: const Icon(Icons.restore),
            label: const Text('Backup visszaállítása fájlból'),
          ),
          const Divider(height: 32),
          FilledButton.icon(
            onPressed: () => _loadSeed(context),
            icon: const Icon(Icons.inventory),
            label: const Text('Alap adatok betöltése'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showExport(context),
            icon: const Icon(Icons.upload),
            label: const Text('JSON export szövegként'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showImport(context),
            icon: const Icon(Icons.download),
            label: const Text('JSON import szövegből'),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackupFile(BuildContext context) async {
    try {
      final backupText = _backupService.buildBackupJson(controller.exportJson());
      final fileName = _backupService.makeBackupFileName();
      final bytes = Uint8List.fromList(utf8.encode(backupText));

      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Brewer Diary backup mentése',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [BackupService.backupExtension, 'json'],
        bytes: bytes,
      );

      if (!context.mounted) return;
      if (savedPath == null) {
        _snack(context, 'Backup mentés megszakítva.');
      } else {
        _snack(context, 'Backup fájl elmentve.');
      }
    } catch (error) {
      if (context.mounted) _snack(context, 'Backup mentés sikertelen: $error');
    }
  }

  Future<void> _restoreBackupFile(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Backup visszaállítása'),
        content: const Text(
          'Ez lecseréli a jelenlegi helyi adatokat a kiválasztott backup tartalmára. Folytassuk?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Mégse')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Visszaállítás')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [BackupService.backupExtension, 'json'],
        withData: true,
      );

      if (!context.mounted) return;
      if (picked == null || picked.files.isEmpty) {
        _snack(context, 'Backup visszaállítás megszakítva.');
        return;
      }

      final file = picked.files.single;
      final bytes = file.bytes ?? (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null) {
        _snack(context, 'A kiválasztott backup fájl nem olvasható.');
        return;
      }

      final backupText = utf8.decode(bytes);
      final batchesJson = _backupService.extractBatchesJson(backupText);
      await controller.importJson(batchesJson);

      if (context.mounted) _snack(context, 'Backup visszaállítva.');
    } catch (error) {
      if (context.mounted) _snack(context, 'Backup visszaállítás sikertelen: $error');
    }
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

  void _showExport(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export JSON'),
        content: SingleChildScrollView(child: SelectableText(controller.exportJson())),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _showImport(BuildContext context) {
    final text = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import JSON szövegből'),
        content: TextField(
          controller: text,
          maxLines: 10,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Illeszd be az exportált JSON-t',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          FilledButton(
            onPressed: () async {
              await controller.importJson(text.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
