import '../calculators/gravity_calculator.dart';
import 'brew_status.dart';
import 'gravity_reading.dart';
import 'ingredient.dart';
import 'tasting_note.dart';

/// Main domain object for one wine/mead/sake/etc. batch.
///
/// This object owns derived values too, such as ABV and age, so the UI can
/// display them consistently without duplicating business logic.
class BrewBatch {
  final String id;
  final String name;
  final String type;
  final BrewStatus status;
  final DateTime startDate;
  final DateTime? bottlingDate;
  final DateTime? rackingDate;
  final DateTime? finishedDate;
  final double? startingGravity;
  final double? endingGravity;
  final double? manualRating;
  final double volumeLiters;
  final String yeast;
  final String notes;
  final List<Ingredient> ingredients;
  final List<GravityReading> gravityReadings;
  final List<TastingNote> tastings;

  const BrewBatch({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.startDate,
    this.bottlingDate,
    this.rackingDate,
    this.finishedDate,
    this.startingGravity,
    this.endingGravity,
    this.manualRating,
    this.volumeLiters = 0,
    this.yeast = '',
    this.notes = '',
    this.ingredients = const [],
    this.gravityReadings = const [],
    this.tastings = const [],
  });

  bool get isIdea => status == BrewStatus.idea;
  bool get isCompleted => !isIdea;

  /// ABV is never edited directly. It is derived from OG and FG.
  double? get abv => GravityCalculator.abv(startingGravity, endingGravity);

  /// Finished batches stop aging on `finishedDate`.
  DateTime get ageEndDate =>
      status == BrewStatus.finished ? (finishedDate ?? DateTime.now()) : DateTime.now();

  /// Age from mixing/start date.
  int get totalAgeDays => ageEndDate.difference(startDate).inDays;

  /// Age from bottling date. Null if the batch has not been bottled yet.
  int? get bottleAgeDays =>
      bottlingDate == null ? null : ageEndDate.difference(bottlingDate!).inDays;

  /// Backward-compatible alias used by older UI code.
  int get ageDays => totalAgeDays;

  /// Average detailed tasting score, falling back to the quick manual rating.
  double get score {
    final scored = tastings.map((tasting) => tasting.average).where((v) => v > 0).toList();
    if (scored.isEmpty) return manualRating ?? 0;
    return scored.reduce((a, b) => a + b) / scored.length;
  }

  BrewBatch copyWith({
    String? name,
    String? type,
    BrewStatus? status,
    DateTime? startDate,
    DateTime? bottlingDate,
    DateTime? rackingDate,
    DateTime? finishedDate,
    double? startingGravity,
    double? endingGravity,
    double? manualRating,
    double? volumeLiters,
    String? yeast,
    String? notes,
    List<Ingredient>? ingredients,
    List<GravityReading>? gravityReadings,
    List<TastingNote>? tastings,
  }) {
    return BrewBatch(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      bottlingDate: bottlingDate ?? this.bottlingDate,
      rackingDate: rackingDate ?? this.rackingDate,
      finishedDate: finishedDate ?? this.finishedDate,
      startingGravity: startingGravity ?? this.startingGravity,
      endingGravity: endingGravity ?? this.endingGravity,
      manualRating: manualRating ?? this.manualRating,
      volumeLiters: volumeLiters ?? this.volumeLiters,
      yeast: yeast ?? this.yeast,
      notes: notes ?? this.notes,
      ingredients: ingredients ?? this.ingredients,
      gravityReadings: gravityReadings ?? this.gravityReadings,
      tastings: tastings ?? this.tastings,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'status': status.name,
        'startDate': startDate.toIso8601String(),
        'bottlingDate': bottlingDate?.toIso8601String(),
        'rackingDate': rackingDate?.toIso8601String(),
        'finishedDate': finishedDate?.toIso8601String(),
        'startingGravity': startingGravity,
        'endingGravity': endingGravity,
        'manualRating': manualRating,
        'volumeLiters': volumeLiters,
        'yeast': yeast,
        'notes': notes,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'gravityReadings': gravityReadings.map((e) => e.toJson()).toList(),
        'tastings': tastings.map((e) => e.toJson()).toList(),
      };

  factory BrewBatch.fromJson(Map<String, dynamic> json) => BrewBatch(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? 'Mead',
        status: statusFromJson(json['status']),
        startDate: DateTime.parse(json['startDate'] as String),
        bottlingDate: json['bottlingDate'] == null
            ? null
            : DateTime.parse(json['bottlingDate'] as String),
        rackingDate: json['rackingDate'] == null
            ? null
            : DateTime.parse(json['rackingDate'] as String),
        finishedDate: json['finishedDate'] == null
            ? null
            : DateTime.parse(json['finishedDate'] as String),
        startingGravity: (json['startingGravity'] as num?)?.toDouble(),
        endingGravity: (json['endingGravity'] as num?)?.toDouble(),
        manualRating: (json['manualRating'] as num?)?.toDouble(),
        volumeLiters: (json['volumeLiters'] as num?)?.toDouble() ?? 0,
        yeast: json['yeast'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        ingredients: (json['ingredients'] as List? ?? [])
            .map((e) => Ingredient.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        gravityReadings: (json['gravityReadings'] as List? ?? [])
            .map((e) => GravityReading.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        tastings: (json['tastings'] as List? ?? [])
            .map((e) => TastingNote.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
