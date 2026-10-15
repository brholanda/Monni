class Expense {
  const Expense({
    this.id,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
  });

  final int? id;
  final double amount;
  final String category;
  final String? description;
  final DateTime date;

  Expense copyWith({
    int? id,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'amount': amount,
        'category': category,
        'description': description,
        'date': date.toIso8601String(),
      };

  factory Expense.fromMap(Map<String, Object?> map) => Expense(
        id: map['id'] as int?,
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String,
        description: map['description'] as String?,
        date: DateTime.parse(map['date'] as String),
      );
}
