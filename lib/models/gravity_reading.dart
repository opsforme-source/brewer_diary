/// One hydrometer/refractometer-style specific gravity reading.
class GravityReading {
  final String id;
  final DateTime date;
  final double sg;
  final String note;

  const GravityReading({
    required this.id,
    required this.date,
    required this.sg,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'sg': sg,
        'note': note,
      };

  factory GravityReading.fromJson(Map<String, dynamic> json) => GravityReading(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        sg: (json['sg'] as num?)?.toDouble() ?? 1,
        note: json['note'] as String? ?? '',
      );
}
