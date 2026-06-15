/// One tasting session with detailed score components.
///
/// The app displays these on the Rating tab. The average only uses fields that
/// are greater than zero, so a partially filled tasting can still be useful.
class TastingNote {
  final String id;
  final DateTime date;
  final double aroma;
  final double taste;
  final double body;
  final double balance;
  final double finishScore;
  final String note;

  const TastingNote({
    required this.id,
    required this.date,
    this.aroma = 0,
    this.taste = 0,
    this.body = 0,
    this.balance = 0,
    this.finishScore = 0,
    this.note = '',
  });

  double get average {
    final values = [aroma, taste, body, balance, finishScore]
        .where((value) => value > 0)
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'aroma': aroma,
        'taste': taste,
        'body': body,
        'balance': balance,
        'finishScore': finishScore,
        'note': note,
      };

  factory TastingNote.fromJson(Map<String, dynamic> json) => TastingNote(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        aroma: (json['aroma'] as num?)?.toDouble() ?? 0,
        taste: (json['taste'] as num?)?.toDouble() ?? 0,
        body: (json['body'] as num?)?.toDouble() ?? 0,
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
        finishScore: (json['finishScore'] as num?)?.toDouble() ?? 0,
        note: json['note'] as String? ?? '',
      );
}
