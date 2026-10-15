import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/expense.dart';
import '../models/income.dart';
import '../models/monthly_summary.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'monni.db';
  static const _dbVersion = 1;

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
    return openDatabase(path, version: _dbVersion, onCreate: _onCreate);
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
