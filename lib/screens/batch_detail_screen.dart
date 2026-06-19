import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/batch_controller.dart';
import '../models/brew_batch.dart';
import '../models/brew_status.dart';
import '../models/gravity_reading.dart';
import '../models/ingredient.dart';
import 'batch_edit_screen.dart';

/// Detailed production/logging view for one batch.
///
/// Sensory scoring is handled on the Rating tab, so this screen stays focused
/// on dates, gravity, ingredients, and notes.
class BatchDetailScreen extends StatelessWidget {
  final BatchController controller;
  final String batchId;

  const BatchDetailScreen({super.key, required this.controller, required this.batchId});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final batch = controller.byId(batchId);
        if (batch == null) {
          return const Scaffold(body: Center(child: Text('A batch eltűnt a pinceködben.')));
        }

        final df = DateFormat('yyyy.MM.dd');
        return Scaffold(
          appBar: AppBar(
            title: Text(batch.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BatchEditScreen(controller: controller, batch: batch),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await controller.delete(batch.id);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section(context, 'Alapadatok'),
              _line('Típus', batch.type),
              _line('Státusz', batch.status.label),
              _line('Kezdés', df.format(batch.startDate)),
              _line('Racking', batch.rackingDate == null ? '-' : df.format(batch.rackingDate!)),
              _line('Palackozás', batch.bottlingDate == null ? '-' : df.format(batch.bottlingDate!)),
              if (batch.finishedDate != null) _line('Elfogyás', df.format(batch.finishedDate!)),
              _line('Teljes kor', '${batch.totalAgeDays} nap'),
              _line('Palackban', batch.bottleAgeDays == null ? '-' : '${batch.bottleAgeDays} nap'),
              _line('Mennyiség', batch.volumeLiters == 0 ? '-' : '${batch.volumeLiters} L'),
              _line('Élesztő', batch.yeast.isEmpty ? '-' : batch.yeast),
              _section(context, 'Gravity és ABV'),
              _line('OG', batch.startingGravity?.toStringAsFixed(3) ?? '-'),
              _line('FG', batch.endingGravity?.toStringAsFixed(3) ?? '-'),
              _line('ABV', batch.abv == null ? '-' : '${batch.abv!.toStringAsFixed(2)}%'),
              _headerButton(context, 'Összetevők', 'Hozzáadás', () => _addIngredient(context, batch)),
              ...batch.ingredients.map(
                (ingredient) => _ingredientTile(context, batch, ingredient),
              ),
              _headerButton(context, 'SG mérések', 'Hozzáadás', () => _addGravity(context, batch)),
              ...batch.gravityReadings.map(
                (reading) => ListTile(
                  title: Text('${reading.sg.toStringAsFixed(3)} SG'),
                  subtitle: Text(
                    '${df.format(reading.date)}${reading.note.isEmpty ? '' : ' • ${reading.note}'}',
                  ),
                ),
              ),
              _section(context, 'Jegyzetek'),
              Text(batch.notes.isEmpty ? 'Nincs jegyzet.' : batch.notes),
            ],
          ),
        );
      },
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      );

  Widget _headerButton(BuildContext context, String title, String button, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
            TextButton.icon(onPressed: onTap, icon: const Icon(Icons.add), label: Text(button)),
          ],
        ),
      );

  Widget _line(String label, String value) => ListTile(title: Text(label), trailing: Text(value));

  Widget _ingredientTile(BuildContext context, BrewBatch batch, Ingredient ingredient) {
    return ListTile(
      title: Text(ingredient.name),
      subtitle: Text(
        '${ingredient.amount} ${ingredient.unit}${ingredient.note.isEmpty ? '' : ' • ${ingredient.note}'}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) {
          if (action == 'edit') _editIngredient(context, batch, ingredient);
          if (action == 'delete') _deleteIngredient(context, batch, ingredient);
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'edit', child: Text('Szerkesztés')),
          PopupMenuItem(value: 'delete', child: Text('Törlés')),
        ],
      ),
    );
  }

  Future<void> _addIngredient(BuildContext context, BrewBatch batch) async {
    final result = await _ingredientDialog(context);
    if (result != null) {
      await controller.upsert(batch.copyWith(ingredients: [...batch.ingredients, result]));
    }
  }

  Future<void> _editIngredient(
    BuildContext context,
    BrewBatch batch,
    Ingredient ingredient,
  ) async {
    final result = await _ingredientDialog(context, existing: ingredient);
    if (result == null) return;

    final updatedIngredients = batch.ingredients
        .map((item) => item.id == ingredient.id ? result : item)
        .toList();
    await controller.upsert(batch.copyWith(ingredients: updatedIngredients));
  }

  Future<void> _deleteIngredient(
    BuildContext context,
    BrewBatch batch,
    Ingredient ingredient,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Összetevő törlése'),
        content: Text('Törlöd ezt az összetevőt?\n\n${ingredient.name}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Mégse')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Törlés')),
        ],
      ),
    );

    if (confirmed != true) return;

    final updatedIngredients = batch.ingredients
        .where((item) => item.id != ingredient.id)
        .toList();
    await controller.upsert(batch.copyWith(ingredients: updatedIngredients));
  }

  Future<Ingredient?> _ingredientDialog(
    BuildContext context, {
    Ingredient? existing,
  }) {
    final name = TextEditingController(text: existing?.name ?? '');
    final amount = TextEditingController(
      text: existing == null || existing.amount == 0 ? '' : existing.amount.toString(),
    );
    final unit = TextEditingController(text: existing?.unit ?? 'g');
    final note = TextEditingController(text: existing?.note ?? '');

    return showDialog<Ingredient>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Új összetevő' : 'Összetevő szerkesztése'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Név')),
            TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mennyiség')),
            TextField(controller: unit, decoration: const InputDecoration(labelText: 'Egység')),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'Jegyzet')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              Ingredient(
                id: existing?.id ?? controller.newId(),
                name: name.text.trim(),
                amount: double.tryParse(amount.text.replaceAll(',', '.')) ?? 0,
                unit: unit.text.trim(),
                note: note.text.trim(),
              ),
            ),
            child: const Text('Mentés'),
          ),
        ],
      ),
    );
  }

  Future<void> _addGravity(BuildContext context, BrewBatch batch) async {
    final sg = TextEditingController();
    final note = TextEditingController();

    final result = await showDialog<GravityReading>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Új SG mérés'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: sg, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'SG')),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'Jegyzet')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              GravityReading(
                id: controller.newId(),
                date: DateTime.now(),
                sg: double.tryParse(sg.text.replaceAll(',', '.')) ?? 1,
                note: note.text.trim(),
              ),
            ),
            child: const Text('Mentés'),
          ),
        ],
      ),
    );

    if (result != null) {
      await controller.upsert(batch.copyWith(gravityReadings: [...batch.gravityReadings, result]));
    }
  }
}
