import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:monni/data/app_backup.dart';
import 'package:monni/data/app_database.dart';
import 'package:monni/screens/backup_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late AppDatabase store;

  setUpAll(() => initializeDateFormatting('pt_PT'));

  Map<String, List<Map<String, Object?>>> sample() => {
        'incomes': [
          {
            'id': 7,
            'title': 'Salário',
            'amount': 1500.0,
            'date': '2026-10-01T00:00:00.000'
          },
        ],
        'expenses': [
          {
            'id': 12,
            'amount': 20.5,
            'category': 'Casa',
            'description': null,
            'date': '2026-09-10T00:00:00.000'
          },
        ],
        'categories': [
          {
            'name': 'Casa',
            'icon_key': 'home',
            'color': 0xff123456,
            'position': 0,
            'enabled': 0
          },
        ],
        'app_settings': [
          {'setting_key': 'font_scale', 'value': '1.2'},
        ],
      };

  setUp(() async {
    sqfliteFfiInit();
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute(
        'CREATE TABLE incomes (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL)');
    await database.execute(
        'CREATE TABLE expenses (id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL NOT NULL, category TEXT NOT NULL, description TEXT, date TEXT NOT NULL)');
    await database.execute(
        'CREATE TABLE categories (name TEXT PRIMARY KEY COLLATE NOCASE, icon_key TEXT NOT NULL, color INTEGER NOT NULL, position INTEGER NOT NULL, enabled INTEGER NOT NULL)');
    await database.execute(
        'CREATE TABLE app_settings (setting_key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    store = AppDatabase.forTesting(database);
  });

  tearDown(() => database.close());

  test('exportação e restauração preservam todos os dados e IDs', () async {
    final backup = AppBackup.fromTables(sample());
    await store.restoreBackup(backup);
    final exported = AppBackup.decode((await store.exportBackup()).encode());
    expect(exported.tables, backup.tables);
    await database.insert(
        'incomes', {'title': 'Extra', 'amount': 10, 'date': '2026-11-01'});
    await store.restoreBackup(exported);
    expect((await store.exportBackup()).tables, backup.tables);
    final nextId = await database.insert(
        'incomes', {'title': 'Novo', 'amount': 10, 'date': '2026-11-01'});
    expect(nextId, greaterThan(7));
  });

  test('backup vazio substitui os registros atuais', () async {
    await store.restoreBackup(AppBackup.fromTables(sample()));
    await store.restoreBackup(AppBackup.fromTables({
      for (final table in AppBackup.tableNames) table: [],
    }));
    expect(
        (await store.exportBackup())
            .tables
            .values
            .every((rows) => rows.isEmpty),
        isTrue);
  });

  test('falha de inserção desfaz toda a restauração', () async {
    await store.restoreBackup(AppBackup.fromTables(sample()));
    final invalid = sample();
    invalid['incomes'] = [];
    invalid['categories']!
        .add({...invalid['categories']!.first, 'name': 'casa'});
    await expectLater(store.restoreBackup(AppBackup.fromTables(invalid)),
        throwsA(isA<DatabaseException>()));
    expect((await store.exportBackup()).tables, sample());
  });

  test('rejeita formato, versão, campos e valores inválidos', () {
    final document = jsonDecode(AppBackup.fromTables(sample()).encode())
        as Map<String, dynamic>;
    expect(() => AppBackup.decode('not json'), throwsFormatException);
    expect(() => AppBackup.decode(jsonEncode({...document, 'version': 99})),
        throwsFormatException);
    expect(() => AppBackup.decode(jsonEncode({...document, 'format': 'other'})),
        throwsFormatException);
    expect(() => AppBackup.decode(jsonEncode({...document, 'data': {}})),
        throwsFormatException);
    final invalid = sample();
    invalid['expenses']!.first['amount'] = -1;
    expect(() => AppBackup.fromTables(invalid), throwsFormatException);
    invalid['expenses']!.first['amount'] = 20;
    invalid['app_settings']!.first['value'] = 'NaN';
    expect(() => AppBackup.fromTables(invalid), throwsFormatException);
  });

  testWidgets('cancelar seleção libera os controles', (tester) async {
    FilePicker.platform = _BackupFilePicker(null);
    await tester.pumpWidget(const MaterialApp(home: BackupScreen()));
    await tester.tap(find.text('Restaurar backup'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(
        tester
            .widget<ListTile>(find.widgetWithText(ListTile, 'Restaurar backup'))
            .enabled,
        isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('arquivo inválido não abre confirmação', (tester) async {
    final bytes = Uint8List.fromList(utf8.encode('{"format":"other"}'));
    FilePicker.platform = _BackupFilePicker(FilePickerResult([
      PlatformFile(name: 'invalid.json', size: bytes.length, bytes: bytes),
    ]));
    await tester.pumpWidget(const MaterialApp(home: BackupScreen()));
    await tester.tap(find.text('Restaurar backup'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('Backup inválido.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'confirmação mostra os registros e permite cancelar em tela pequena',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bytes = Uint8List.fromList(
        utf8.encode(AppBackup.fromTables(sample()).encode()));
    FilePicker.platform = _BackupFilePicker(FilePickerResult([
      PlatformFile(name: 'backup.json', size: bytes.length, bytes: bytes),
    ]));
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.5)),
        child: child!,
      ),
      home: const BackupScreen(),
    ));
    await tester.tap(find.text('Restaurar backup'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('1 entradas, 1 gastos e 1 categorias.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Cancelar'));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Backup restaurado com sucesso.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _BackupFilePicker extends FilePicker {
  _BackupFilePicker(this.result);

  final FilePickerResult? result;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async =>
      result;
}
