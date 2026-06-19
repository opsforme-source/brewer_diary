import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/batch_controller.dart';
import '../models/brew_batch.dart';
import '../models/brew_status.dart';
import '../models/tasting_note.dart';

/// Dedicated scoring tab.
///
/// This keeps sensory evaluation separate from production metadata. Only
/// bottled/finished batches appear here by default.
class RatingScreen extends StatelessWidget {
  final BatchController controller;
  const RatingScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy.MM.dd');
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final batches = controller.bottled;
        return Scaffold(
          appBar: AppBar(title: const Text('Pontozás')),
          body: batches.isEmpty
              ? const Center(child: Text('Még nincs pontozható palackozott tétel.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: batches.length,
                  itemBuilder: (context, index) {
                    final batch = batches[index];
                    final latest = batch.tastings.isEmpty ? null : batch.tastings.last;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    batch.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  batch.score == 0 ? '-' : batch.score.toStringAsFixed(1),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            Text('${batch.type} • ${df.format(batch.startDate)} • ${batch.status.label}'),
                            const SizedBox(height: 12),
                            if (latest == null)
                              const Text('Még nincs részletes pontozás.')
                            else ...[
                              Text('Legutóbbi kóstolás: ${df.format(latest.date)}'),
                              const SizedBox(height: 8),
                              _scoreRow('Illat', latest.aroma),
                              _scoreRow('Íz', latest.taste),
                              _scoreRow('Test', latest.body),
                              _scoreRow('Egyensúly', latest.balance),
                              _scoreRow('Utóíz', latest.finishScore),
                              if (latest.note.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(latest.note),
                                ),
                            ],
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: () => _addTasting(context, batch),
                                icon: const Icon(Icons.add),
                                label: const Text('Pontozás hozzáadása'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _scoreRow(String label, double value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 90, child: Text(label)),
            Expanded(child: LinearProgressIndicator(value: value.clamp(0, 10) / 10)),
            const SizedBox(width: 12),
            Text(value == 0 ? '-' : value.toStringAsFixed(1)),
          ],
        ),
      );

  Future<void> _addTasting(BuildContext context, BrewBatch batch) async {
    final aroma = TextEditingController();
    final taste = TextEditingController();
    final body = TextEditingController();
    final balance = TextEditingController();
    final finish = TextEditingController();
    final note = TextEditingController();

    double parseScore(String value) => double.tryParse(value.replaceAll(',', '.')) ?? 0;

    final result = await showDialog<TastingNote>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${batch.name} pontozása'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: aroma, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Illat 0-10')),
              TextField(controller: taste, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Íz 0-10')),
              TextField(controller: body, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Test 0-10')),
              TextField(controller: balance, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Egyensúly 0-10')),
              TextField(controller: finish, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Utóíz 0-10')),
              TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Jegyzet')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              TastingNote(
                id: controller.newId(),
                date: DateTime.now(),
                aroma: parseScore(aroma.text),
                taste: parseScore(taste.text),
                body: parseScore(body.text),
                balance: parseScore(balance.text),
                finishScore: parseScore(finish.text),
                note: note.text.trim(),
              ),
            ),
            child: const Text('Mentés'),
          ),
        ],
      ),
    );

    if (result != null) {
      await controller.upsert(batch.copyWith(tastings: [...batch.tastings, result]));
    }
  }
}
