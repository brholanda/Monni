import 'package:flutter/foundation.dart';

import '../models/expense_category.dart';
import 'app_database.dart';

/// Cache em memória das categorias, para que os ecrãs possam resolver
/// nome -> ícone/cor de forma síncrona durante o build.
class CategoryStore extends ChangeNotifier {
  CategoryStore._();

  static final CategoryStore instance = CategoryStore._();

  List<ExpenseCategory> _categories = kDefaultCategories;

  List<ExpenseCategory> get categories => _categories;

  List<ExpenseCategory> get enabled =>
      _categories.where((c) => c.enabled).toList();

  List<ExpenseCategory> get disabled =>
      _categories.where((c) => !c.enabled).toList();

  Future<void> load() async {
    _categories = await AppDatabase.instance.categories();
    notifyListeners();
  }

  ExpenseCategory byName(String name) {
    for (final category in _categories) {
      if (category.name == name) return category;
    }
    return fallbackCategoryFor(name);
  }

  bool exists(String name, {String? ignoring}) {
    final normalized = name.trim().toLowerCase();
    return _categories.any(
      (c) =>
          c.name.toLowerCase() == normalized &&
          c.name.toLowerCase() != ignoring?.toLowerCase(),
    );
  }
}

ExpenseCategory categoryByName(String name) =>
    CategoryStore.instance.byName(name);
