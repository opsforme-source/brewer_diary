import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/brew_batch.dart';

/// Owns the in-memory batch list and persistence.
///
/// Screens talk to this controller instead of reading/writing SharedPreferences
/// directly. That keeps storage decisions in one place.
class BatchController extends ChangeNotifier {
  static const _storageKey = 'brewer_diary_batches_v3';
  static const _oldStorageKey = 'brewer_diary_batches_v2';
  static const _olderStorageKey = 'brewer_diary_batches_v1';

  final _uuid = const Uuid();
  List<BrewBatch> _batches = [];
  bool loaded = false;

  List<BrewBatch> get batches {
    final sorted = [..._batches]..sort((a, b) => b.startDate.compareTo(a.startDate));
    return sorted;
  }

  List<BrewBatch> get ideas => batches.where((batch) => batch.isIdea).toList();
  List<BrewBatch> get completed => batches.where((batch) => batch.isCompleted).toList();

  String newId() => _uuid.v4();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey) ??
        prefs.getString(_oldStorageKey) ??
        prefs.getString(_olderStorageKey);

    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _batches = decoded
          .map((e) => BrewBatch.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    loaded = true;
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_batches.map((batch) => batch.toJson()).toList()),
    );
  }

  Future<void> upsert(BrewBatch batch) async {
    final index = _batches.indexWhere((item) => item.id == batch.id);
    if (index == -1) {
      _batches.add(batch);
    } else {
      _batches[index] = batch;
    }
    await _save();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _batches.removeWhere((batch) => batch.id == id);
    await _save();
    notifyListeners();
  }

  BrewBatch? byId(String id) {
    for (final batch in _batches) {
      if (batch.id == id) return batch;
    }
    return null;
  }

  String exportJson() =>
      const JsonEncoder.withIndent('  ').convert(_batches.map((e) => e.toJson()).toList());

  Future<void> importJson(String text) async {
    final decoded = jsonDecode(text) as List<dynamic>;
    _batches = decoded
        .map((e) => BrewBatch.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    await _save();
    notifyListeners();
  }
}
