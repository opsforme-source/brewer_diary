import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../controllers/batch_controller.dart';

/// Import/export and maintenance actions.
///
/// The seed import is bundled as an asset so the initial spreadsheet data does
/// not need to be pasted into a tiny textbox.
class SettingsScreen extends StatelessWidget {
  final BatchController controller;
  const SettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beállítások')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: () => _loadSeed(context),
            icon: const Icon(Icons.inventory),
            label: const Text('Alap adatok betöltése'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _showExport(context),
            icon: const Icon(Icons.upload),
            label: const Text('JSON export'),
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

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alap adatok betöltve.')),
      );
    }
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
}
