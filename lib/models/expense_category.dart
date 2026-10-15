import 'package:flutter/material.dart';

class ExpenseCategory {
  const ExpenseCategory({
    required this.name,
    required this.iconKey,
    required this.color,
    this.enabled = true,
  });

  final String name;
  final String iconKey;
  final Color color;
  final bool enabled;

  IconData get icon => categoryIconFor(iconKey);

  Map<String, Object?> toMap() => {
        'name': name,
        'icon_key': iconKey,
        'color': color.toARGB32(),
        'enabled': enabled ? 1 : 0,
      };

  factory ExpenseCategory.fromMap(Map<String, Object?> map) => ExpenseCategory(
        name: map['name'] as String,
        iconKey: map['icon_key'] as String,
        color: Color(map['color'] as int),
        enabled: (map['enabled'] as int? ?? 1) == 1,
      );
}

/// Guardamos a chave do ícone (e não o codepoint) para não quebrar o
/// tree-shaking de ícones no build.
const kCategoryIcons = <String, IconData>{
  'restaurant': Icons.restaurant_rounded,
  'fastfood': Icons.fastfood_rounded,
  'coffee': Icons.local_cafe_rounded,
  'grocery': Icons.local_grocery_store_rounded,
  'bus': Icons.directions_bus_rounded,
  'car': Icons.directions_car_rounded,
  'fuel': Icons.local_gas_station_rounded,
  'flight': Icons.flight_rounded,
  'home': Icons.home_rounded,
  'bed': Icons.bed_rounded,
  'bolt': Icons.bolt_rounded,
  'water': Icons.water_drop_rounded,
  'wifi': Icons.wifi_rounded,
  'phone': Icons.smartphone_rounded,
  'health': Icons.favorite_rounded,
  'medication': Icons.medication_rounded,
  'fitness': Icons.fitness_center_rounded,
  'school': Icons.school_rounded,
  'book': Icons.menu_book_rounded,
  'work': Icons.work_rounded,
  'games': Icons.sports_esports_rounded,
  'movie': Icons.movie_rounded,
  'music': Icons.music_note_rounded,
  'travel': Icons.luggage_rounded,
  'shopping': Icons.shopping_bag_rounded,
  'gift': Icons.card_giftcard_rounded,
  'pets': Icons.pets_rounded,
  'child': Icons.child_friendly_rounded,
  'receipt': Icons.receipt_long_rounded,
  'bank': Icons.account_balance_rounded,
  'savings': Icons.savings_rounded,
  'card': Icons.credit_card_rounded,
  'build': Icons.build_rounded,
  'cut': Icons.content_cut_rounded,
  'star': Icons.star_rounded,
  'category': Icons.category_rounded,
};

IconData categoryIconFor(String key) =>
    kCategoryIcons[key] ?? Icons.category_rounded;

const kCategoryPalette = <Color>[
  Color(0xFFE2574C),
  Color(0xFF2F6BFF),
  Color(0xFF8E5BDA),
  Color(0xFFE05C9E),
  Color(0xFF00A5B5),
  Color(0xFFF2A03D),
  Color(0xFF1FA97A),
  Color(0xFF6C7A93),
  Color(0xFF9AA5B1),
  Color(0xFFD4A017),
  Color(0xFF4CAF50),
  Color(0xFF7E57C2),
];

const kFallbackCategory = ExpenseCategory(
  name: 'Outros',
  iconKey: 'category',
  color: Color(0xFF9AA5B1),
);

const kDefaultCategories = <ExpenseCategory>[
  ExpenseCategory(
    name: 'Alimentação',
    iconKey: 'restaurant',
    color: Color(0xFFE2574C),
  ),
  ExpenseCategory(
    name: 'Transportes',
    iconKey: 'bus',
    color: Color(0xFF2F6BFF),
  ),
  ExpenseCategory(name: 'Habitação', iconKey: 'home', color: Color(0xFF8E5BDA)),
  ExpenseCategory(name: 'Saúde', iconKey: 'health', color: Color(0xFFE05C9E)),
  ExpenseCategory(
    name: 'Educação',
    iconKey: 'school',
    color: Color(0xFF00A5B5),
  ),
  ExpenseCategory(name: 'Lazer', iconKey: 'games', color: Color(0xFFF2A03D)),
  ExpenseCategory(
    name: 'Compras',
    iconKey: 'shopping',
    color: Color(0xFF1FA97A),
  ),
  ExpenseCategory(
    name: 'Serviços',
    iconKey: 'receipt',
    color: Color(0xFF6C7A93),
  ),
  kFallbackCategory,
];
