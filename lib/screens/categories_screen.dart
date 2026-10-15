import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/category_store.dart';
import '../models/expense_category.dart';
import '../theme/app_theme.dart';
import '../widgets/dialog_header.dart';
import '../widgets/empty_state.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _db = AppDatabase.instance;
  final _store = CategoryStore.instance;

  late Future<Map<String, int>> _counts;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _counts = _db.expenseCountByCategory();
  }

  Future<void> _refresh() async {
    await _store.load();
    if (mounted) setState(_reload);
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _create() async {
    final category = await showModalBottomSheet<ExpenseCategory>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryFormSheet(
        isDuplicate: (name) => _store.exists(name),
        suggestedColor: kCategoryPalette[
            _store.categories.length % kCategoryPalette.length],
      ),
    );
    if (category == null) return;

    final created = await _db.insertCategory(category);
    if (!created) {
      _notify('Já existe uma categoria com esse nome.');
      return;
    }
    await _refresh();
    _notify('Categoria "${category.name}" criada.');
  }

  Future<void> _edit(ExpenseCategory category) async {
    final edited = await showModalBottomSheet<ExpenseCategory>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryFormSheet(
        isDuplicate: (name) => _store.exists(name, ignoring: category.name),
        suggestedColor: category.color,
        initial: category,
      ),
    );
    if (edited == null) return;

    final updated = await _db.updateCategory(category.name, edited);
    if (!updated) {
      _notify('Já existe uma categoria com esse nome.');
      return;
    }
    await _refresh();
    _notify('Categoria "${edited.name}" atualizada.');
  }

  Future<void> _setEnabled(ExpenseCategory category, bool enabled) async {
    if (!enabled && _store.enabled.length <= 1) {
      _notify('Tem de existir pelo menos uma categoria ativa.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: DialogHeader(
          title: enabled ? 'Reativar categoria?' : 'Desativar categoria?',
          onClose: () => Navigator.pop(context, false),
        ),
        content: Text(
          enabled
              ? '"${category.name}" volta a ficar disponível no registo '
                  'de gastos.'
              : '"${category.name}" deixa de aparecer no registo de gastos. '
                  'Os gastos já existentes mantêm-se inalterados.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _db.setCategoryEnabled(category.name, enabled);
    await _refresh();
    _notify(
      enabled
          ? 'Categoria "${category.name}" reativada.'
          : 'Categoria "${category.name}" desativada.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categorias'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ativas'),
              Tab(text: 'Desativadas'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _create,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nova'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: FutureBuilder<Map<String, int>>(
                future: _counts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final counts = snapshot.data ?? const <String, int>{};
                  return TabBarView(
                    children: [
                      _CategoryList(
                        categories: _store.enabled,
                        counts: counts,
                        emptyMessage: 'Ainda não existem categorias ativas.',
                        actionIcon: Icons.visibility_off_rounded,
                        actionTooltip: 'Desativar',
                        onAction: (c) => _setEnabled(c, false),
                        onEdit: _edit,
                      ),
                      _CategoryList(
                        categories: _store.disabled,
                        counts: counts,
                        emptyMessage: 'Nenhuma categoria desativada.',
                        actionIcon: Icons.restart_alt_rounded,
                        actionTooltip: 'Reativar',
                        onAction: (c) => _setEnabled(c, true),
                        onEdit: _edit,
                        dimmed: true,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.categories,
    required this.counts,
    required this.emptyMessage,
    required this.actionIcon,
    required this.actionTooltip,
    required this.onAction,
    required this.onEdit,
    this.dimmed = false,
  });

  final List<ExpenseCategory> categories;
  final Map<String, int> counts;
  final String emptyMessage;
  final IconData actionIcon;
  final String actionTooltip;
  final ValueChanged<ExpenseCategory> onAction;
  final ValueChanged<ExpenseCategory> onEdit;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return EmptyState(icon: Icons.category_rounded, message: emptyMessage);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final category = categories[index];
        final count = counts[category.name] ?? 0;
        return Opacity(
          opacity: dimmed ? 0.6 : 1,
          child: AppCard(
            child: ListTile(
              onTap: () => onEdit(category),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: category.color),
              ),
              title: Text(
                category.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(count == 1 ? '1 gasto' : '$count gastos'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => onEdit(category),
                  ),
                  IconButton(
                    tooltip: actionTooltip,
                    icon: Icon(actionIcon),
                    onPressed: () => onAction(category),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({
    required this.isDuplicate,
    required this.suggestedColor,
    this.initial,
  });

  final bool Function(String name) isDuplicate;
  final Color suggestedColor;
  final ExpenseCategory? initial;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.initial?.name ?? '');

  late Color _color = widget.initial?.color ?? widget.suggestedColor;
  late String _iconKey = widget.initial?.iconKey ?? kCategoryIcons.keys.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ExpenseCategory(
        name: _nameController.text.trim(),
        iconKey: _iconKey,
        color: _color,
        enabled: widget.initial?.enabled ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconKeys = kCategoryIcons.keys.toList();
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DialogHeader(
              title: widget.initial == null
                  ? 'Nova categoria'
                  : 'Editar categoria',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: 'Nome',
                counterText: '',
              ),
              validator: (value) {
                final name = (value ?? '').trim();
                if (name.isEmpty) return 'Indique um nome';
                if (widget.isDuplicate(name)) {
                  return 'Já existe uma categoria com esse nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('Cor', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in kCategoryPalette)
                  GestureDetector(
                    onTap: () => setState(() => _color = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == color
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Ícone', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            SizedBox(
              height: 190,
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: iconKeys.length,
                itemBuilder: (context, index) {
                  final key = iconKeys[index];
                  final selected = key == _iconKey;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _iconKey = key),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? _color.withValues(alpha: 0.18)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? _color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        categoryIconFor(key),
                        color: selected
                            ? _color
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              child: Text(widget.initial == null ? 'Criar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
