import 'package:flutter/material.dart';

import '../controllers/batch_controller.dart';
import '../models/brew_status.dart';
import 'batch_detail_screen.dart';
import 'batch_edit_screen.dart';

/// Displays planned brews separately from completed/active batches.
class IdeasScreen extends StatelessWidget {
  final BatchController controller;
  const IdeasScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Ötletek')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BatchEditScreen(
                controller: controller,
                initialStatus: BrewStatus.idea,
              ),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Új ötlet'),
        ),
        body: !controller.loaded
            ? const Center(child: CircularProgressIndicator())
            : controller.ideas.isEmpty
                ? const Center(
                    child: Text('Még nincs ötlet. Jöhet az első palackba zárt gondolat.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                    itemCount: controller.ideas.length,
                    itemBuilder: (context, index) {
                      final batch = controller.ideas[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            batch.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${batch.type}\n${batch.notes.isEmpty ? 'Nincs jegyzet.' : batch.notes}',
                          ),
                          isThreeLine: true,
                          trailing: FilledButton(
                            onPressed: () => controller.upsert(
                              batch.copyWith(
                                status: BrewStatus.fermenting,
                                startDate: DateTime.now(),
                              ),
                            ),
                            child: const Text('Indítás'),
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BatchDetailScreen(
                                controller: controller,
                                batchId: batch.id,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
