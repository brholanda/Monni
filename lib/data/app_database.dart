import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/income.dart';
import '../models/monthly_summary.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'monni.db';
  static const _dbVersion = 3;

  Database? _db;

  Future<Database> get database async {
    return _db ??= await _open();
  }

  /// sqflite só tem implementação nativa em Android/iOS; nas restantes
  /// plataformas é preciso usar o backend FFI (web ou desktop).
  static bool _factoryReady = false;

  static void _ensureFactory() {
    if (_factoryReady) return;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _factoryReady = true;
  }

  Future<Database> _open() async {
    _ensureFactory();
    final path = kIsWeb
        ? _dbName
        : p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_incomes_date ON incomes(date)');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
    await _createCategories(db);
    await _seedCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCategories(db);
      await _seedCategories(db);
    }
    if (oldVersion == 2) {
      await db.execute(
        'ALTER TABLE categories ADD COLUMN enabled INTEGER NOT NULL DEFAULT 1',
      );
    }
  }

  Future<void> _createCategories(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        name TEXT PRIMARY KEY COLLATE NOCASE,
        icon_key TEXT NOT NULL,
        color INTEGER NOT NULL,
        position INTEGER NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Future<void> _seedCategories(Database db) async {
    final batch = db.batch();
    for (var i = 0; i < kDefaultCategories.length; i++) {
      batch.insert(
        'categories',
        kDefaultCategories[i].toMap()..['position'] = i,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    // Preserva categorias que já existiam em gastos antes da tabela existir.
    final orphans = await db.rawQuery(
      'SELECT DISTINCT category FROM expenses',
    );
    var position = kDefaultCategories.length;
    for (final row in orphans) {
      final name = row['category'] as String;
      batch.insert(
        'categories',
        ExpenseCategory(
          name: name,
          iconKey: kFallbackCategory.iconKey,
          color: kCategoryPalette[position % kCategoryPalette.length],
        ).toMap()
          ..['position'] = position,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      position++;
    }
    await batch.commit(noResult: true);
  }

  // ------------------------------------------------------------- categories

  Future<List<ExpenseCategory>> categories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'position, name');
    return rows.map(ExpenseCategory.fromMap).toList();
  }

  /// Devolve `false` se já existir uma categoria com o mesmo nome.
  Future<bool> insertCategory(ExpenseCategory category) async {
    final db = await database;
    final maxRow = await db.rawQuery(
      'SELECT COALESCE(MAX(position), -1) AS max FROM categories',
    );
    final position = (maxRow.first['max'] as num).toInt() + 1;
    final id = await db.insert(
      'categories',
      category.toMap()..['position'] = position,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return id != 0;
  }

  Future<int> setCategoryEnabled(String name, bool enabled) async {
    final db = await database;
    return db.update(
      'categories',
      {'enabled': enabled ? 1 : 0},
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  /// Atualiza uma categoria; se o nome mudar, os gastos associados acompanham.
  /// Devolve `false` se o novo nome colidir com outra categoria.
  Future<bool> updateCategory(
    String previousName,
    ExpenseCategory category,
  ) async {
    final db = await database;
    if (previousName.toLowerCase() != category.name.toLowerCase()) {
      final clash = await db.query(
        'categories',
        where: 'name = ?',
        whereArgs: [category.name],
        limit: 1,
      );
      if (clash.isNotEmpty) return false;
    }
    await db.transaction((txn) async {
      await txn.update(
        'categories',
        {
          'name': category.name,
          'icon_key': category.iconKey,
          'color': category.color.toARGB32(),
        },
        where: 'name = ?',
        whereArgs: [previousName],
      );
      if (previousName != category.name) {
        await txn.update(
          'expenses',
          {'category': category.name},
          where: 'category = ?',
          whereArgs: [previousName],
        );
      }
    });
    return true;
  }

  Future<Map<String, int>> expenseCountByCategory() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT category, COUNT(*) AS total FROM expenses GROUP BY category',
    );
    return {
      for (final row in rows)
        row['category'] as String: (row['total'] as num).toInt(),
    };
  }

  // ---------------------------------------------------------------- incomes

  Future<int> insertIncome(Income income) async {
    final db = await database;
    return db.insert('incomes', income.toMap()..remove('id'));
  }

  Future<int> updateIncome(Income income) async {
    final db = await database;
    return db.update(
      'incomes',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<int> deleteIncome(int id) async {
    final db = await database;
    return db.delete('incomes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Income>> incomesForMonth(DateTime month) async {
    final db = await database;
    final range = _monthRange(month);
    final rows = await db.query(
      'incomes',
      where: 'date >= ? AND date < ?',
      whereArgs: range,
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Income.fromMap).toList();
  }

  // --------------------------------------------------------------- expenses

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return db.insert('expenses', expense.toMap()..remove('id'));
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> expensesForMonth(DateTime month) async {
    final db = await database;
    final range = _monthRange(month);
    final rows = await db.query(
      'expenses',
      where: 'date >= ? AND date < ?',
      whereArgs: range,
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  // ---------------------------------------------------------------- summary

  Future<MonthlySummary> summaryForMonth(DateTime month) async {
    final db = await database;
    final range = _monthRange(month);

    final incomeRow = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM incomes '
      'WHERE date >= ? AND date < ?',
      range,
    );
    final expenseRow = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses '
      'WHERE date >= ? AND date < ?',
      range,
    );
    final categoryRows = await db.rawQuery(
      'SELECT category, SUM(amount) AS total FROM expenses '
      'WHERE date >= ? AND date < ? '
      'GROUP BY category ORDER BY total DESC',
      range,
    );

    return MonthlySummary(
      totalIncome: (incomeRow.first['total'] as num).toDouble(),
      totalExpense: (expenseRow.first['total'] as num).toDouble(),
      byCategory: {
        for (final row in categoryRows)
          row['category'] as String: (row['total'] as num).toDouble(),
      },
    );
  }

  List<String> _monthRange(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    return [start.toIso8601String(), end.toIso8601String()];
  }
}
