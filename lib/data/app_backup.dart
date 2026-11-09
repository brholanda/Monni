import 'dart:convert';

class AppBackup {
  AppBackup._(this.createdAt, this.tables);

  static const version = 1;
  static const tableNames = [
    'incomes',
    'expenses',
    'categories',
    'app_settings'
  ];

  final DateTime createdAt;
  final Map<String, List<Map<String, Object?>>> tables;

  factory AppBackup.fromTables(Map<String, List<Map<String, Object?>>> tables) {
    return AppBackup.decode(jsonEncode({
      'format': 'monni-backup',
      'version': version,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'data': tables,
    }));
  }

  factory AppBackup.decode(String source) {
    final document = jsonDecode(source);
    if (document is! Map<String, dynamic> ||
        document['format'] != 'monni-backup' ||
        document['version'] != version ||
        document['created_at'] is! String ||
        document['data'] is! Map<String, dynamic>) {
      throw const FormatException('Formato ou versão de backup incompatível.');
    }
    final createdAt = DateTime.tryParse(document['created_at'] as String);
    if (createdAt == null) {
      throw const FormatException('Data do backup inválida.');
    }
    final data = document['data'] as Map<String, dynamic>;
    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in tableNames) {
      final rows = data[table];
      if (rows is! List) {
        throw const FormatException('Dados do backup incompletos.');
      }
      tables[table] = rows.map((row) {
        if (row is! Map<String, dynamic> || !_validRow(table, row)) {
          throw const FormatException('O backup contém registros inválidos.');
        }
        return Map<String, Object?>.from(row);
      }).toList();
    }
    return AppBackup._(createdAt, tables);
  }

  String encode() => const JsonEncoder.withIndent('  ').convert({
        'format': 'monni-backup',
        'version': version,
        'created_at': createdAt.toUtc().toIso8601String(),
        'data': tables,
      });

  static bool _validRow(String table, Map<String, dynamic> row) {
    bool text(String key) =>
        row[key] is String && (row[key] as String).trim().isNotEmpty;
    bool integer(String key) => row[key] is int;
    switch (table) {
      case 'incomes':
      case 'expenses':
        final fields = table == 'incomes'
            ? {'id', 'title', 'amount', 'date'}
            : {'id', 'amount', 'category', 'description', 'date'};
        return row.length == fields.length &&
            fields.every(row.containsKey) &&
            integer('id') &&
            (row['id'] as int) > 0 &&
            row['amount'] is num &&
            (row['amount'] as num).isFinite &&
            (row['amount'] as num) > 0 &&
            text('date') &&
            DateTime.tryParse(row['date'] as String) != null &&
            (table == 'incomes'
                ? text('title')
                : text('category') &&
                    (row['description'] == null ||
                        row['description'] is String));
      case 'categories':
        return row.length == 5 &&
            text('name') &&
            text('icon_key') &&
            integer('color') &&
            (row['color'] as int) >= 0 &&
            (row['color'] as int) <= 0xffffffff &&
            integer('position') &&
            (row['position'] as int) >= 0 &&
            integer('enabled') &&
            (row['enabled'] == 0 || row['enabled'] == 1);
      case 'app_settings':
        final scale = row['value'] is String
            ? double.tryParse(row['value'] as String)
            : null;
        return row.length == 2 &&
            row['setting_key'] == 'font_scale' &&
            scale != null &&
            scale.isFinite &&
            scale >= 0.9 &&
            scale <= 1.5;
      default:
        return false;
    }
  }
}
