class Income {
  const Income({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
  });

  final int? id;
  final String title;
  final double amount;
  final DateTime date;

  Income copyWith({int? id, String? title, double? amount, DateTime? date}) {
    return Income(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory Income.fromMap(Map<String, Object?> map) => Income(
        id: map['id'] as int?,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        date: DateTime.parse(map['date'] as String),
      );
}
