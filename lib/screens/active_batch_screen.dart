import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/batch_controller.dart';
import '../models/brew_status.dart';
import 'batch_detail_screen.dart';
import 'batch_edit_screen.dart';

/// Separate work-in-progress list for fermenting/secondary/aging batches.
class ActiveBatchScreen extends StatefulWidget {
  final BatchController controller;
  const ActiveBatchScreen({super.key, required this.controller});

  @override
  State<ActiveBatchScreen> createState() => _ActiveBatchScreenState();
}

class _ActiveBatchScreenState extends State<ActiveBatchScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy.MM.dd');
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final batches = widget.controller.active.where((batch) {
          final q = query.toLowerCase();
          return batch.name.toLowerCase().contains(q) ||
              batch.type.toLowerCase().contains(q) ||
              batch.ingredients.any((ingredient) => ingredient.name.toLowerCase().contains(q));
        }).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Folyamatban')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BatchEditScreen(controller: widget.controller)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Új batch'),
          ),
          body: !widget.controller.loaded
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          labelText: 'Keresés név, típus vagy alapanyag alapján',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() => query = value),
                      ),
                    ),
                    Expanded(
                      child: batches.isEmpty
                          ? const Center(child: Text('Nincs folyamatban lévő brew.'))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                              itemCount: batches.length,
                              itemBuilder: (context, index) {
                                final batch = batches[index];
                                return Card(
                                  child: ListTile(
                                    title: Text(
                                      batch.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      '${batch.type} • ${df.format(batch.startDate)} • ${batch.status.label}\n'
                                      'OG: ${_sg(batch.startingGravity)} | FG: ${_sg(batch.endingGravity)} | ABV: ${_percent(batch.abv)}\n'
                                      'Teljes kor: ${batch.totalAgeDays} nap',
                                    ),
                                    isThreeLine: true,
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => BatchDetailScreen(
                                          controller: widget.controller,
                                          batchId: batch.id,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  String _sg(double? value) => value == null ? '-' : value.toStringAsFixed(3);
  String _percent(double? value) => value == null ? '-' : '${value.toStringAsFixed(1)}%';
}
