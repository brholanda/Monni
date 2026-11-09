import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/accessibility_settings.dart';
import '../data/app_backup.dart';
import '../data/app_database.dart';
import '../data/category_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/dialog_header.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  static const _maxBackupBytes = 20 * 1024 * 1024;
  bool _busy = false;
  String? _status;

  Future<void> _export(Rect shareOrigin) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final backup = await AppDatabase.instance.exportBackup();
      final bytes = utf8.encode(backup.encode());
      if (bytes.length > _maxBackupBytes) {
        if (mounted) {
          setState(() => _status = 'O backup excede o limite de 20 MB.');
        }
        return;
      }
      final timestamp = backup.createdAt.toIso8601String().replaceAll(':', '-');
      final result = await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'application/json')],
        fileNameOverrides: ['monni-backup-$timestamp.json'],
        subject: 'Backup do Monni',
        sharePositionOrigin: shareOrigin,
      );
      if (!mounted) return;
      setState(() {
        _status = result.status == ShareResultStatus.dismissed
            ? 'Exportação cancelada.'
            : 'Backup exportado. Guarde o arquivo em um local seguro.';
      });
    } catch (_) {
      if (mounted) {
        setState(() =>
            _status = 'Não foi possível exportar o backup. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: kIsWeb,
      );
      if (selection == null || !mounted) return;
      final file = selection.files.single;
      if (file.size > _maxBackupBytes) {
        throw const FormatException('O arquivo excede o limite de 20 MB.');
      }
      final bytes = file.bytes ?? await file.xFile.readAsBytes();
      final backup = AppBackup.decode(utf8.decode(bytes));
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: DialogHeader(
            title: 'Restaurar backup?',
            onClose: () => Navigator.pop(context, false),
          ),
          content: SingleChildScrollView(
            child: Text(
              'Backup de ${formatDate(backup.createdAt.toLocal())}: '
              '${backup.tables['incomes']!.length} entradas, '
              '${backup.tables['expenses']!.length} gastos e '
              '${backup.tables['categories']!.length} categorias.\n\n'
              'Todos os dados atuais serão substituídos, inclusive o tamanho da fonte. '
              'Esta ação não pode ser desfeita. O bloqueio da aplicação não será alterado.',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Substituir e restaurar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await AppDatabase.instance.restoreBackup(backup);
      await CategoryStore.instance.load();
      await AccessibilitySettings.instance.load();
      if (mounted) setState(() => _status = 'Backup restaurado com sucesso.');
    } on FormatException catch (error) {
      if (mounted) {
        setState(() => _status = 'Backup inválido. ${error.message}');
      }
    } catch (_) {
      if (mounted) {
        setState(() =>
            _status = 'Não foi possível restaurar o backup. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Backup')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AppCard(
                    child: Column(
                      children: [
                        Builder(
                          builder: (buttonContext) => ListTile(
                            enabled: !_busy,
                            leading: const Icon(Icons.ios_share_rounded),
                            title: const Text('Exportar backup'),
                            onTap: _busy
                                ? null
                                : () {
                                    final box = buttonContext
                                        .findRenderObject()! as RenderBox;
                                    _export(box.localToGlobal(Offset.zero) &
                                        box.size);
                                  },
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          enabled: !_busy,
                          leading: const Icon(Icons.restore_rounded),
                          title: const Text('Restaurar backup'),
                          onTap: _busy ? null : _restore,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'O arquivo contém dados financeiros pessoais e não é criptografado. '
                    'O PIN e a biometria não são incluídos.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (_status != null) ...[
                    const SizedBox(height: 24),
                    Semantics(liveRegion: true, child: Text(_status!)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
