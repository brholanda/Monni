import 'package:flutter/material.dart';

class ExpenseCategory {
  const ExpenseCategory(this.name, this.icon, this.color);

  final String name;
  final IconData icon;
  final Color color;
}

const kExpenseCategories = <ExpenseCategory>[
  ExpenseCategory('Alimentação', Icons.restaurant_rounded, Color(0xFFE2574C)),
  ExpenseCategory('Transportes', Icons.directions_bus_rounded, Color(0xFF2F6BFF)),
  ExpenseCategory('Habitação', Icons.home_rounded, Color(0xFF8E5BDA)),
  ExpenseCategory('Saúde', Icons.favorite_rounded, Color(0xFFE05C9E)),
  ExpenseCategory('Educação', Icons.school_rounded, Color(0xFF00A5B5)),
  ExpenseCategory('Lazer', Icons.sports_esports_rounded, Color(0xFFF2A03D)),
  ExpenseCategory('Compras', Icons.shopping_bag_rounded, Color(0xFF1FA97A)),
  ExpenseCategory('Serviços', Icons.receipt_long_rounded, Color(0xFF6C7A93)),
  ExpenseCategory('Outros', Icons.category_rounded, Color(0xFF9AA5B1)),
];

ExpenseCategory categoryByName(String name) {
  return kExpenseCategories.firstWhere(
    (c) => c.name == name,
    orElse: () => kExpenseCategories.last,
  );
}
