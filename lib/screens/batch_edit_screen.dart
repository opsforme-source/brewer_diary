import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/batch_controller.dart';
import '../models/brew_batch.dart';
import '../models/brew_status.dart';
import '../models/brew_type.dart';

/// Create/edit form for both ideas and real batches.
///
/// FG defaults to 1.000 for new batches because that is the common target, but
/// it remains editable. ABV is not editable here because it is derived from OG
/// and FG in the domain model.
class BatchEditScreen extends StatefulWidget {
  final BatchController controller;
  final BrewBatch? batch;
  final BrewStatus initialStatus;

  const BatchEditScreen({
    super.key,
    required this.controller,
    this.batch,
    this.initialStatus = BrewStatus.fermenting,
  });

  @override
  State<BatchEditScreen> createState() => _BatchEditScreenState();
}

class _BatchEditScreenState extends State<BatchEditScreen> {
  final name = TextEditingController();
  final og = TextEditingController();
  final fg = TextEditingController();
  final rating = TextEditingController();
  final volume = TextEditingController();
  final yeast = TextEditingController();
  final notes = TextEditingController();

  String selectedType = 'Mead';
  DateTime startDate = DateTime.now();
  DateTime? bottlingDate;
  DateTime? rackingDate;
  DateTime? finishedDate;
  late BrewStatus status;

  @override
  void initState() {
    super.initState();
    status = widget.initialStatus;

    final batch = widget.batch;
    if (batch != null) {
      name.text = batch.name;
      selectedType = batch.type.isEmpty ? 'Other' : batch.type;
      og.text = batch.startingGravity?.toStringAsFixed(3) ?? '';
      fg.text = batch.endingGravity?.toStringAsFixed(3) ?? '';
      rating.text = batch.manualRating?.toStringAsFixed(1) ?? '';
      volume.text = batch.volumeLiters == 0 ? '' : batch.volumeLiters.toString();
      yeast.text = batch.yeast;
      notes.text = batch.notes;
      startDate = batch.startDate;
      bottlingDate = batch.bottlingDate;
      rackingDate = batch.rackingDate;
      finishedDate = batch.finishedDate;
      status = batch.status;
    } else {
      selectedType = 'Mead';
      fg.text = '1.000';
    }
  }

  @override
  void dispose() {
    name.dispose();
    og.dispose();
    fg.dispose();
    rating.dispose();
    volume.dispose();
    yeast.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy.MM.dd');
    final typeOptions = brewTypeOptionsFor(selectedType);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.batch == null
            ? (status == BrewStatus.idea ? 'Új ötlet' : 'Új batch')
            : 'Szerkesztés'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(name, 'Név'),
          DropdownButtonFormField<String>(
            value: selectedType,
            decoration: const InputDecoration(
              labelText: 'Típus',
              border: OutlineInputBorder(),
            ),
            items: typeOptions
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) => setState(() => selectedType = value ?? selectedType),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<BrewStatus>(
            value: status,
            decoration: const InputDecoration(labelText: 'Státusz'),
            items: BrewStatus.values
                .map((status) => DropdownMenuItem(value: status, child: Text(status.label)))
                .toList(),
            onChanged: (value) => setState(() {
              status = value ?? status;
              if (status == BrewStatus.finished) finishedDate ??= DateTime.now();
            }),
          ),
          const SizedBox(height: 12),
          _dateTile('Kezdés dátuma', df.format(startDate), () async {
            final picked = await _pickDate(startDate);
            if (picked != null) setState(() => startDate = picked);
          }),
          _dateTile('Racking dátuma', rackingDate == null ? '-' : df.format(rackingDate!), () async {
            final picked = await _pickDate(rackingDate ?? DateTime.now());
            if (picked != null) setState(() => rackingDate = picked);
          }),
          _dateTile('Palackozás dátuma', bottlingDate == null ? '-' : df.format(bottlingDate!), () async {
            final picked = await _pickDate(bottlingDate ?? DateTime.now());
            if (picked != null) setState(() => bottlingDate = picked);
          }),
          if (status == BrewStatus.finished)
            _dateTile('Elfogyás dátuma', df.format(finishedDate ?? DateTime.now()), () async {
              final picked = await _pickDate(finishedDate ?? DateTime.now());
              if (picked != null) setState(() => finishedDate = picked);
            }),
          _field(volume, 'Mennyiség literben', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          _field(og, 'Starting Gravity / OG', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          _field(fg, 'Ending Gravity / FG', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          _field(rating, 'Gyors rating 0-10', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          _field(yeast, 'Élesztő'),
          _field(notes, 'Jegyzetek', maxLines: 5),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Mentés'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _dateTile(String title, String value, VoidCallback onTap) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
        trailing: const Icon(Icons.calendar_month),
        onTap: onTap,
      ),
    );
  }

  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );

  double? _parseDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  Future<void> _save() async {
    final old = widget.batch;
    final normalizedFinishedDate =
        status == BrewStatus.finished ? (finishedDate ?? old?.finishedDate ?? DateTime.now()) : null;

    final batch = BrewBatch(
      id: old?.id ?? widget.controller.newId(),
      name: name.text.trim().isEmpty ? 'Névtelen batch' : name.text.trim(),
      type: selectedType,
      status: status,
      startDate: startDate,
      bottlingDate: bottlingDate,
      rackingDate: rackingDate,
      finishedDate: normalizedFinishedDate,
      startingGravity: _parseDouble(og.text),
      endingGravity: _parseDouble(fg.text),
      manualRating: _parseDouble(rating.text),
      volumeLiters: _parseDouble(volume.text) ?? 0,
      yeast: yeast.text.trim(),
      notes: notes.text.trim(),
      ingredients: old?.ingredients ?? [],
      gravityReadings: old?.gravityReadings ?? [],
      tastings: old?.tastings ?? [],
    );

    await widget.controller.upsert(batch);
    if (mounted) Navigator.of(context).pop();
  }
}
