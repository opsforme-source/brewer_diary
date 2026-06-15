/// One ingredient used in a batch.
///
/// Sugar calculations can be added here later without changing the batch UI.
class Ingredient {
  final String id;
  final String name;
  final double amount;
  final String unit;
  final String note;

  const Ingredient({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'unit': unit,
        'note': note,
      };

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );
}
