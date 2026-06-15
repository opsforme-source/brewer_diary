import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BrewerDiaryApp());
}

class BrewerDiaryApp extends StatefulWidget {
  const BrewerDiaryApp({super.key});
  @override
  State<BrewerDiaryApp> createState() => _BrewerDiaryAppState();
}

class _BrewerDiaryAppState extends State<BrewerDiaryApp> {
  late final BatchController controller;
  @override
  void initState() {
    super.initState();
    controller = BatchController()..load();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Brewer Diary',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B1E4D)), useMaterial3: true),
        darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B1E4D), brightness: Brightness.dark), useMaterial3: true),
        home: MainShell(controller: controller),
      );
}

class MainShell extends StatefulWidget {
  final BatchController controller;
  const MainShell({super.key, required this.controller});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [IdeasScreen(controller: widget.controller), BatchListScreen(controller: widget.controller), RatingScreen(controller: widget.controller), SettingsScreen(controller: widget.controller)];
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.lightbulb_outline), selectedIcon: Icon(Icons.lightbulb), label: 'Ötletek'),
          NavigationDestination(icon: Icon(Icons.local_bar_outlined), selectedIcon: Icon(Icons.local_bar), label: 'Elkészült'),
          NavigationDestination(icon: Icon(Icons.star_outline), selectedIcon: Icon(Icons.star), label: 'Pontozás'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Beállítások'),
        ],
      ),
    );
  }
}

class GravityCalculator {
  static double? abv(double? og, double? fg) {
    if (og == null || fg == null || og <= 0 || fg <= 0) return null;
    return (og - fg) * 131.25;
  }
}

enum BrewStatus { idea, fermenting, secondary, aging, bottled, finished }

extension BrewStatusLabel on BrewStatus {
  String get label => switch (this) {
        BrewStatus.idea => 'Ötlet',
        BrewStatus.fermenting => 'Erjed',
        BrewStatus.secondary => 'Másodlagos',
        BrewStatus.aging => 'Érlelődik',
        BrewStatus.bottled => 'Palackozva',
        BrewStatus.finished => 'Elfogyott',
      };
}

BrewStatus statusFromJson(dynamic value) {
  if (value == 'planned') return BrewStatus.idea;
  return BrewStatus.values.firstWhere((s) => s.name == value, orElse: () => BrewStatus.fermenting);
}

class Ingredient {
  final String id;
  final String name;
  final double amount;
  final String unit;
  final String note;
  const Ingredient({required this.id, required this.name, required this.amount, required this.unit, this.note = ''});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'amount': amount, 'unit': unit, 'note': note};
  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(id: json['id'] as String, name: json['name'] as String? ?? '', amount: (json['amount'] as num?)?.toDouble() ?? 0, unit: json['unit'] as String? ?? '', note: json['note'] as String? ?? '');
}

class GravityReading {
  final String id;
  final DateTime date;
  final double sg;
  final String note;
  const GravityReading({required this.id, required this.date, required this.sg, this.note = ''});
  Map<String, dynamic> toJson() => {'id': id, 'date': date.toIso8601String(), 'sg': sg, 'note': note};
  factory GravityReading.fromJson(Map<String, dynamic> json) => GravityReading(id: json['id'] as String, date: DateTime.parse(json['date'] as String), sg: (json['sg'] as num?)?.toDouble() ?? 1, note: json['note'] as String? ?? '');
}

class TastingNote {
  final String id;
  final DateTime date;
  final double aroma;
  final double taste;
  final double body;
  final double balance;
  final double finishScore;
  final String note;
  const TastingNote({required this.id, required this.date, this.aroma = 0, this.taste = 0, this.body = 0, this.balance = 0, this.finishScore = 0, this.note = ''});
  double get average {
    final values = [aroma, taste, body, balance, finishScore].where((v) => v > 0).toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  Map<String, dynamic> toJson() => {'id': id, 'date': date.toIso8601String(), 'aroma': aroma, 'taste': taste, 'body': body, 'balance': balance, 'finishScore': finishScore, 'note': note};
  factory TastingNote.fromJson(Map<String, dynamic> json) => TastingNote(id: json['id'] as String, date: DateTime.parse(json['date'] as String), aroma: (json['aroma'] as num?)?.toDouble() ?? 0, taste: (json['taste'] as num?)?.toDouble() ?? 0, body: (json['body'] as num?)?.toDouble() ?? 0, balance: (json['balance'] as num?)?.toDouble() ?? 0, finishScore: (json['finishScore'] as num?)?.toDouble() ?? 0, note: json['note'] as String? ?? '');
}

class BrewBatch {
  final String id;
  final String name;
  final String type;
  final BrewStatus status;
  final DateTime startDate;
  final DateTime? bottlingDate;
  final DateTime? rackingDate;
  final double? startingGravity;
  final double? endingGravity;
  final double? manualRating;
  final double volumeLiters;
  final String yeast;
  final String notes;
  final List<Ingredient> ingredients;
  final List<GravityReading> gravityReadings;
  final List<TastingNote> tastings;
  const BrewBatch({required this.id, required this.name, required this.type, required this.status, required this.startDate, this.bottlingDate, this.rackingDate, this.startingGravity, this.endingGravity, this.manualRating, this.volumeLiters = 0, this.yeast = '', this.notes = '', this.ingredients = const [], this.gravityReadings = const [], this.tastings = const []});
  bool get isIdea => status == BrewStatus.idea;
  bool get isCompleted => !isIdea;
  double? get abv => GravityCalculator.abv(startingGravity, endingGravity);
  int get ageDays => DateTime.now().difference(bottlingDate ?? startDate).inDays;
  double get score {
    final scored = tastings.map((t) => t.average).where((v) => v > 0).toList();
    if (scored.isEmpty) return manualRating ?? 0;
    return scored.reduce((a, b) => a + b) / scored.length;
  }

  BrewBatch copyWith({String? name, String? type, BrewStatus? status, DateTime? startDate, DateTime? bottlingDate, DateTime? rackingDate, double? startingGravity, double? endingGravity, double? manualRating, double? volumeLiters, String? yeast, String? notes, List<Ingredient>? ingredients, List<GravityReading>? gravityReadings, List<TastingNote>? tastings}) => BrewBatch(id: id, name: name ?? this.name, type: type ?? this.type, status: status ?? this.status, startDate: startDate ?? this.startDate, bottlingDate: bottlingDate ?? this.bottlingDate, rackingDate: rackingDate ?? this.rackingDate, startingGravity: startingGravity ?? this.startingGravity, endingGravity: endingGravity ?? this.endingGravity, manualRating: manualRating ?? this.manualRating, volumeLiters: volumeLiters ?? this.volumeLiters, yeast: yeast ?? this.yeast, notes: notes ?? this.notes, ingredients: ingredients ?? this.ingredients, gravityReadings: gravityReadings ?? this.gravityReadings, tastings: tastings ?? this.tastings);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'type': type, 'status': status.name, 'startDate': startDate.toIso8601String(), 'bottlingDate': bottlingDate?.toIso8601String(), 'rackingDate': rackingDate?.toIso8601String(), 'startingGravity': startingGravity, 'endingGravity': endingGravity, 'manualRating': manualRating, 'volumeLiters': volumeLiters, 'yeast': yeast, 'notes': notes, 'ingredients': ingredients.map((e) => e.toJson()).toList(), 'gravityReadings': gravityReadings.map((e) => e.toJson()).toList(), 'tastings': tastings.map((e) => e.toJson()).toList()};
  factory BrewBatch.fromJson(Map<String, dynamic> json) => BrewBatch(id: json['id'] as String, name: json['name'] as String? ?? '', type: json['type'] as String? ?? 'Mead', status: statusFromJson(json['status']), startDate: DateTime.parse(json['startDate'] as String), bottlingDate: json['bottlingDate'] == null ? null : DateTime.parse(json['bottlingDate'] as String), rackingDate: json['rackingDate'] == null ? null : DateTime.parse(json['rackingDate'] as String), startingGravity: (json['startingGravity'] as num?)?.toDouble(), endingGravity: (json['endingGravity'] as num?)?.toDouble(), manualRating: (json['manualRating'] as num?)?.toDouble(), volumeLiters: (json['volumeLiters'] as num?)?.toDouble() ?? 0, yeast: json['yeast'] as String? ?? '', notes: json['notes'] as String? ?? '', ingredients: (json['ingredients'] as List? ?? []).map((e) => Ingredient.fromJson(Map<String, dynamic>.from(e))).toList(), gravityReadings: (json['gravityReadings'] as List? ?? []).map((e) => GravityReading.fromJson(Map<String, dynamic>.from(e))).toList(), tastings: (json['tastings'] as List? ?? []).map((e) => TastingNote.fromJson(Map<String, dynamic>.from(e))).toList());
}

class BatchController extends ChangeNotifier {
  static const _storageKey = 'brewer_diary_batches_v2';
  static const _oldStorageKey = 'brewer_diary_batches_v1';
  final _uuid = const Uuid();
  List<BrewBatch> _batches = [];
  bool loaded = false;
  List<BrewBatch> get batches {
    final sorted = [..._batches]..sort((a, b) => b.startDate.compareTo(a.startDate));
    return sorted;
  }

  List<BrewBatch> get ideas => batches.where((b) => b.isIdea).toList();
  List<BrewBatch> get completed => batches.where((b) => b.isCompleted).toList();
  String newId() => _uuid.v4();
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey) ?? prefs.getString(_oldStorageKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _batches = decoded.map((e) => BrewBatch.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    loaded = true;
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_batches.map((e) => e.toJson()).toList()));
  }

  Future<void> upsert(BrewBatch batch) async {
    final index = _batches.indexWhere((b) => b.id == batch.id);
    if (index == -1) {
      _batches.add(batch);
    } else {
      _batches[index] = batch;
    }
    await _save();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _batches.removeWhere((b) => b.id == id);
    await _save();
    notifyListeners();
  }

  BrewBatch? byId(String id) {
    for (final batch in _batches) {
      if (batch.id == id) return batch;
    }
    return null;
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(_batches.map((e) => e.toJson()).toList());
  Future<void> importJson(String text) async {
    final decoded = jsonDecode(text) as List<dynamic>;
    _batches = decoded.map((e) => BrewBatch.fromJson(Map<String, dynamic>.from(e))).toList();
    await _save();
    notifyListeners();
  }
}

class IdeasScreen extends StatelessWidget {
  final BatchController controller;
  const IdeasScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: const Text('Ötletek')),
          floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BatchEditScreen(controller: controller, initialStatus: BrewStatus.idea))), icon: const Icon(Icons.add), label: const Text('Új ötlet')),
          body: !controller.loaded ? const Center(child: CircularProgressIndicator()) : controller.ideas.isEmpty ? const Center(child: Text('Még nincs ötlet. Jöhet az első palackba zárt gondolat.')) : ListView.builder(padding: const EdgeInsets.fromLTRB(12, 12, 12, 88), itemCount: controller.ideas.length, itemBuilder: (context, index) {
            final batch = controller.ideas[index];
            return Card(child: ListTile(title: Text(batch.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${batch.type}\n${batch.notes.isEmpty ? 'Nincs jegyzet.' : batch.notes}'), isThreeLine: true, trailing: FilledButton(onPressed: () => controller.upsert(batch.copyWith(status: BrewStatus.fermenting, startDate: DateTime.now())), child: const Text('Indítás')), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BatchDetailScreen(controller: controller, batchId: batch.id)))));
          }),
        ),
      );
}

class BatchListScreen extends StatefulWidget {
  final BatchController controller;
  const BatchListScreen({super.key, required this.controller});
  @override
  State<BatchListScreen> createState() => _BatchListScreenState();
}

class _BatchListScreenState extends State<BatchListScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy.MM.dd');
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final batches = widget.controller.completed.where((batch) {
          final q = query.toLowerCase();
          return batch.name.toLowerCase().contains(q) || batch.type.toLowerCase().contains(q) || batch.ingredients.any((i) => i.name.toLowerCase().contains(q));
        }).toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Elkészült borok')),
          floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BatchEditScreen(controller: widget.controller))), icon: const Icon(Icons.add), label: const Text('Új batch')),
          body: !widget.controller.loaded ? const Center(child: CircularProgressIndicator()) : Column(children: [
            Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Keresés név, típus vagy alapanyag alapján', border: OutlineInputBorder()), onChanged: (value) => setState(() => query = value))),
            Expanded(child: batches.isEmpty ? const Center(child: Text('Még nincs elkészült batch.')) : ListView.builder(padding: const EdgeInsets.fromLTRB(12, 0, 12, 88), itemCount: batches.length, itemBuilder: (context, index) {
              final batch = batches[index];
              return Card(child: ListTile(title: Text(batch.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${batch.type} • ${df.format(batch.startDate)} • ${batch.status.label}\nOG: ${_sg(batch.startingGravity)} | FG: ${_sg(batch.endingGravity)} | ABV: ${_percent(batch.abv)} | Age: ${batch.ageDays} nap'), isThreeLine: true, trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BatchDetailScreen(controller: widget.controller, batchId: batch.id)))));
            })),
          ]),
        );
      },
    );
  }

  String _sg(double? value) => value == null ? '-' : value.toStringAsFixed(3);
  String _percent(double? value) => value == null ? '-' : '${value.toStringAsFixed(1)}%';
}

class RatingScreen extends StatelessWidget {
  final BatchController controller;
  const RatingScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy.MM.dd');
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final batches = controller.completed;
        return Scaffold(
          appBar: AppBar(title: const Text('Pontozás')),
          body: batches.isEmpty ? const Center(child: Text('Még nincs pontozható elkészült tétel.')) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: batches.length, itemBuilder: (context, index) {
            final batch = batches[index];
            final latest = batch.tastings.isEmpty ? null : batch.tastings.last;
            return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(batch.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))), Text(batch.score == 0 ? '-' : batch.score.toStringAsFixed(1), style: Theme.of(context).textTheme.titleLarge)]),
              Text('${batch.type} • ${df.format(batch.startDate)} • ${batch.status.label}'),
              const SizedBox(height: 12),
              if (latest == null) const Text('Még nincs részletes pontozás.') else ...[Text('Legutóbbi kóstolás: ${df.format(latest.date)}'), const SizedBox(height: 8), _scoreRow('Illat', latest.aroma), _scoreRow('Íz', latest.taste), _scoreRow('Test', latest.body), _scoreRow('Egyensúly', latest.balance), _scoreRow('Utóíz', latest.finishScore), if (latest.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(latest.note))],
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: () => _addTasting(context, batch), icon: const Icon(Icons.add), label: const Text('Pontozás hozzáadása'))),
            ])));
          }),
        );
      },
    );
  }

  Widget _scoreRow(String label, double value) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [SizedBox(width: 90, child: Text(label)), Expanded(child: LinearProgressIndicator(value: value.clamp(0, 10) / 10)), const SizedBox(width: 12), Text(value == 0 ? '-' : value.toStringAsFixed(1))]));
  Future<void> _addTasting(BuildContext context, BrewBatch batch) async {
    final aroma = TextEditingController();
    final taste = TextEditingController();
    final body = TextEditingController();
    final balance = TextEditingController();
    final finish = TextEditingController();
    final note = TextEditingController();
    double p(String v) => double.tryParse(v.replaceAll(',', '.')) ?? 0;
    final result = await showDialog<TastingNote>(context: context, builder: (_) => AlertDialog(title: Text('${batch.name} pontozása'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: aroma, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Illat 0-10')), TextField(controller: taste, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Íz 0-10')), TextField(controller: body, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Test 0-10')), TextField(controller: balance, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Egyensúly 0-10')), TextField(controller: finish, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Utóíz 0-10')), TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Jegyzet'))])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')), FilledButton(onPressed: () => Navigator.pop(context, TastingNote(id: controller.newId(), date: DateTime.now(), aroma: p(aroma.text), taste: p(taste.text), body: p(body.text), balance: p(balance.text), finishScore: p(finish.text), note: note.text.trim())), child: const Text('Mentés'))]));
    if (result != null) await controller.upsert(batch.copyWith(tastings: [...batch.tastings, result]));
  }
}

class BatchEditScreen extends StatefulWidget {
  final BatchController controller;
  final BrewBatch? batch;
  final BrewStatus initialStatus;
  const BatchEditScreen({super.key, required this.controller, this.batch, this.initialStatus = BrewStatus.fermenting});
  @override
  State<BatchEditScreen> createState() => _BatchEditScreenState();
}

class _BatchEditScreenState extends State<BatchEditScreen> {
  final name = TextEditingController();
  final type = TextEditingController();
  final og = TextEditingController();
  final fg = TextEditingController();
  final rating = TextEditingController();
  final volume = TextEditingController();
  final yeast = TextEditingController();
  final notes = TextEditingController();
  DateTime startDate = DateTime.now();
  DateTime? bottlingDate;
  DateTime? rackingDate;
  late BrewStatus status;
  @override
  void initState() {
    super.initState();
    status = widget.initialStatus;
    final batch = widget.batch;
    if (batch != null) {
      name.text = batch.name;
      type.text = batch.type;
      og.text = batch.startingGravity?.toStringAsFixed(3) ?? '';
      fg.text = batch.endingGravity?.toStringAsFixed(3) ?? '';
      rating.text = batch.manualRating?.toStringAsFixed(1) ?? '';
      volume.text = batch.volumeLiters == 0 ? '' : batch.volumeLiters.toString();
      yeast.text = batch.yeast;
      notes.text = batch.notes;
      startDate = batch.startDate;
      bottlingDate = batch.bottlingDate;
      rackingDate = batch.rackingDate;
      status = batch.status;
    } else {
      type.text = 'Mead';
      fg.text = '1.000';
    }
  }

  @override
  void dispose() {
    name.dispose(); type.dispose(); og.dispose(); fg.dispose(); rating.dispose(); volume.dispose(); yeast.dispose(); notes.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy.MM.dd');
    return Scaffold(appBar: AppBar(title: Text(widget.batch == null ? (status == BrewStatus.idea ? 'Új ötlet' : 'Új batch') : 'Szerkesztés')), body: ListView(padding: const EdgeInsets.all(16), children: [
      _field(name, 'Név'), _field(type, 'Típus'), DropdownButtonFormField<BrewStatus>(value: status, decoration: const InputDecoration(labelText: 'Státusz'), items: BrewStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(), onChanged: (value) => setState(() => status = value ?? status)), const SizedBox(height: 12),
      _dateTile('Kezdés dátuma', df.format(startDate), () async { final picked = await _pickDate(startDate); if (picked != null) setState(() => startDate = picked); }),
      _dateTile('Racking dátuma', rackingDate == null ? '-' : df.format(rackingDate!), () async { final picked = await _pickDate(rackingDate ?? DateTime.now()); if (picked != null) setState(() => rackingDate = picked); }),
      _dateTile('Palackozás dátuma', bottlingDate == null ? '-' : df.format(bottlingDate!), () async { final picked = await _pickDate(bottlingDate ?? DateTime.now()); if (picked != null) setState(() => bottlingDate = picked); }),
      _field(volume, 'Mennyiség literben', keyboardType: const TextInputType.numberWithOptions(decimal: true)), _field(og, 'Starting Gravity / OG', keyboardType: const TextInputType.numberWithOptions(decimal: true)), _field(fg, 'Ending Gravity / FG', keyboardType: const TextInputType.numberWithOptions(decimal: true)), _field(rating, 'Gyors rating 0-10', keyboardType: const TextInputType.numberWithOptions(decimal: true)), _field(yeast, 'Élesztő'), _field(notes, 'Jegyzetek', maxLines: 5), const SizedBox(height: 20), FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Mentés')),
    ]));
  }

  Widget _field(TextEditingController controller, String label, {TextInputType? keyboardType, int maxLines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: controller, keyboardType: keyboardType, maxLines: maxLines, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())));
  Widget _dateTile(String title, String value, VoidCallback onTap) => Card(child: ListTile(title: Text(title), subtitle: Text(value), trailing: const Icon(Icons.calendar_month), onTap: onTap));
  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2020), lastDate: DateTime(2100));
  double? _parseDouble(String value) { final normalized = value.trim().replaceAll(',', '.'); if (normalized.isEmpty) return null; return double.tryParse(normalized); }
  Future<void> _save() async {
    final old = widget.batch;
    final batch = BrewBatch(id: old?.id ?? widget.controller.newId(), name: name.text.trim().isEmpty ? 'Névtelen batch' : name.text.trim(), type: type.text.trim().isEmpty ? 'Egyéb' : type.text.trim(), status: status, startDate: startDate, bottlingDate: bottlingDate, rackingDate: rackingDate, startingGravity: _parseDouble(og.text), endingGravity: _parseDouble(fg.text), manualRating: _parseDouble(rating.text), volumeLiters: _parseDouble(volume.text) ?? 0, yeast: yeast.text.trim(), notes: notes.text.trim(), ingredients: old?.ingredients ?? [], gravityReadings: old?.gravityReadings ?? [], tastings: old?.tastings ?? []);
    await widget.controller.upsert(batch);
    if (mounted) Navigator.of(context).pop();
  }
}

class BatchDetailScreen extends StatelessWidget {
  final BatchController controller;
  final String batchId;
  const BatchDetailScreen({super.key, required this.controller, required this.batchId});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: controller, builder: (context, _) {
    final batch = controller.byId(batchId);
    if (batch == null) return const Scaffold(body: Center(child: Text('A batch eltűnt a pinceködben.')));
    final df = DateFormat('yyyy.MM.dd');
    return Scaffold(appBar: AppBar(title: Text(batch.name), actions: [IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BatchEditScreen(controller: controller, batch: batch)))), IconButton(icon: const Icon(Icons.delete), onPressed: () async { await controller.delete(batch.id); if (context.mounted) Navigator.of(context).pop(); })]), body: ListView(padding: const EdgeInsets.all(16), children: [
      _section(context, 'Alapadatok'), _line('Típus', batch.type), _line('Státusz', batch.status.label), _line('Kezdés', df.format(batch.startDate)), _line('Racking', batch.rackingDate == null ? '-' : df.format(batch.rackingDate!)), _line('Palackozás', batch.bottlingDate == null ? '-' : df.format(batch.bottlingDate!)), _line('Kor', '${batch.ageDays} nap'), _line('Mennyiség', batch.volumeLiters == 0 ? '-' : '${batch.volumeLiters} L'), _line('Élesztő', batch.yeast.isEmpty ? '-' : batch.yeast),
      _section(context, 'Gravity és ABV'), _line('OG', batch.startingGravity?.toStringAsFixed(3) ?? '-'), _line('FG', batch.endingGravity?.toStringAsFixed(3) ?? '-'), _line('ABV', batch.abv == null ? '-' : '${batch.abv!.toStringAsFixed(2)}%'),
      _headerButton(context, 'Összetevők', 'Hozzáadás', () => _addIngredient(context, batch)), ...batch.ingredients.map((i) => ListTile(title: Text(i.name), subtitle: Text('${i.amount} ${i.unit}${i.note.isEmpty ? '' : ' • ${i.note}'}'))),
      _headerButton(context, 'SG mérések', 'Hozzáadás', () => _addGravity(context, batch)), ...batch.gravityReadings.map((g) => ListTile(title: Text('${g.sg.toStringAsFixed(3)} SG'), subtitle: Text('${df.format(g.date)}${g.note.isEmpty ? '' : ' • ${g.note}'}'))),
      _section(context, 'Jegyzetek'), Text(batch.notes.isEmpty ? 'Nincs jegyzet.' : batch.notes),
    ]));
  });
  Widget _section(BuildContext context, String title) => Padding(padding: const EdgeInsets.only(top: 24, bottom: 8), child: Text(title, style: Theme.of(context).textTheme.titleLarge));
  Widget _headerButton(BuildContext context, String title, String button, VoidCallback onTap) => Padding(padding: const EdgeInsets.only(top: 24, bottom: 8), child: Row(children: [Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)), TextButton.icon(onPressed: onTap, icon: const Icon(Icons.add), label: Text(button))]));
  Widget _line(String label, String value) => ListTile(title: Text(label), trailing: Text(value));
  Future<void> _addIngredient(BuildContext context, BrewBatch batch) async {
    final name = TextEditingController(); final amount = TextEditingController(); final unit = TextEditingController(text: 'g'); final note = TextEditingController();
    final result = await showDialog<Ingredient>(context: context, builder: (_) => AlertDialog(title: const Text('Új összetevő'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Név')), TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mennyiség')), TextField(controller: unit, decoration: const InputDecoration(labelText: 'Egység')), TextField(controller: note, decoration: const InputDecoration(labelText: 'Jegyzet'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')), FilledButton(onPressed: () => Navigator.pop(context, Ingredient(id: controller.newId(), name: name.text.trim(), amount: double.tryParse(amount.text.replaceAll(',', '.')) ?? 0, unit: unit.text.trim(), note: note.text.trim())), child: const Text('Mentés'))]));
    if (result != null) await controller.upsert(batch.copyWith(ingredients: [...batch.ingredients, result]));
  }
  Future<void> _addGravity(BuildContext context, BrewBatch batch) async {
    final sg = TextEditingController(); final note = TextEditingController();
    final result = await showDialog<GravityReading>(context: context, builder: (_) => AlertDialog(title: const Text('Új SG mérés'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: sg, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'SG')), TextField(controller: note, decoration: const InputDecoration(labelText: 'Jegyzet'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')), FilledButton(onPressed: () => Navigator.pop(context, GravityReading(id: controller.newId(), date: DateTime.now(), sg: double.tryParse(sg.text.replaceAll(',', '.')) ?? 1, note: note.text.trim())), child: const Text('Mentés'))]));
    if (result != null) await controller.upsert(batch.copyWith(gravityReadings: [...batch.gravityReadings, result]));
  }
}

class SettingsScreen extends StatelessWidget {
  final BatchController controller;
  const SettingsScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Beállítások')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(onPressed: () => _loadSeed(context), icon: const Icon(Icons.inventory), label: const Text('Alap adatok betöltése')),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: () => _showExport(context), icon: const Icon(Icons.upload), label: const Text('JSON export')),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: () => _showImport(context), icon: const Icon(Icons.download), label: const Text('JSON import szövegből')),
          ],
        ),
      );

  Future<void> _loadSeed(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alap adatok betöltése'),
        content: const Text('Ez lecseréli a jelenlegi helyi adatokat a beépített táblázat-importtal. Mehet?'),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alap adatok betöltve.')));
    }
  }

  void _showExport(BuildContext context) => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Export JSON'), content: SingleChildScrollView(child: SelectableText(controller.exportJson())), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
  void _showImport(BuildContext context) {
    final text = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Import JSON szövegből'), content: TextField(controller: text, maxLines: 10, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Illeszd be az exportált JSON-t')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')), FilledButton(onPressed: () async { await controller.importJson(text.text); if (context.mounted) Navigator.pop(context); }, child: const Text('Import'))]));
  }
}
