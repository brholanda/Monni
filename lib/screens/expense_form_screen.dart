import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_database.dart';
import '../data/category_store.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/category_form_sheet.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.expense});

  final Expense? expense;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late String _category;
  late List<ExpenseCategory> _options;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _amountController = TextEditingController(
      text: expense == null ? '' : expense.amount.toStringAsFixed(2),
    );
    _descriptionController =
        TextEditingController(text: expense?.description ?? '');
    _options = CategoryStore.instance.enabled;
    if (expense != null && !_options.any((c) => c.name == expense.category)) {
      // A categoria do gasto em edição pode estar desativada.
      _options = [..._options, CategoryStore.instance.byName(expense.category)];
    }
    _category =
        expense?.category ?? (_options.isEmpty ? '' : _options.first.name);
    _date = expense?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'PT'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _selectCategory() async {
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryPickerSheet(
        categories: _options,
        selectedCategory: _category,
      ),
    );
    if (!mounted || result == null) return;

    if (result is ExpenseCategory) {
      setState(() => _category = result.name);
      return;
    }
    if (result == _CategoryPickerAction.newCategory) {
      await _createCategory();
    }
  }

  Future<void> _createCategory() async {
    final store = CategoryStore.instance;
    final category = await showModalBottomSheet<ExpenseCategory>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryFormSheet(
        isDuplicate: store.exists,
        suggestedColor:
            kCategoryPalette[store.categories.length % kCategoryPalette.length],
      ),
    );
    if (category == null) return;

    final created = await AppDatabase.instance.insertCategory(category);
    if (!mounted) return;
    if (!created) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Já existe uma categoria com esse nome.')),
      );
      return;
    }

    await store.load();
    if (mounted) {
      setState(() {
        _options = store.enabled;
        _category = category.name;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);

    final description = _descriptionController.text.trim();
    final expense = Expense(
      id: widget.expense?.id,
      amount: parseAmount(_amountController.text)!,
      category: _category,
      description: description.isEmpty ? null : description,
      date: DateTime(_date.year, _date.month, _date.day),
    );

    final db = AppDatabase.instance;
    try {
      if (expense.id == null) {
        await db.insertExpense(expense);
      } else {
        await db.updateExpense(expense);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível guardar: $e')),
      );
      return;
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar gasto' : 'Novo gasto')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      prefixText: '\$ ',
                    ),
                    validator: (value) => parseAmount(value ?? '') == null
                        ? 'Indique um valor válido maior que zero'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _selectCategory,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CategoryStore.instance.byName(_category).icon,
                            color:
                                CategoryStore.instance.byName(_category).color,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_category)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 120,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                      counterText: '',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Data'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatDate(_date)),
                          const Icon(Icons.calendar_today_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(isEditing ? 'Guardar' : 'Adicionar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _CategoryPickerAction { newCategory }

class _CategoryPickerSheet extends StatefulWidget {
  const _CategoryPickerSheet({
    required this.categories,
    required this.selectedCategory,
  });

  final List<ExpenseCategory> categories;
  final String selectedCategory;

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final categories = widget.categories
        .where(
            (category) => category.name.toLowerCase().contains(normalizedQuery))
        .toList()
      ..sort(
        (first, second) =>
            first.name.toLowerCase().compareTo(second.name.toLowerCase()),
      );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Selecionar categoria',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Pesquisar categoria',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    for (final category in categories)
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        leading: Icon(category.icon, color: category.color),
                        title: Text(category.name),
                        trailing: category.name == widget.selectedCategory
                            ? const Icon(Icons.check_rounded)
                            : null,
                        onTap: () => Navigator.pop(context, category),
                      ),
                    if (categories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(
                          child: Text('Nenhuma categoria encontrada.'),
                        ),
                      ),
                    const Divider(),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(Icons.add_rounded),
                      title: const Text('Cadastrar nova categoria'),
                      onTap: () => Navigator.pop(
                        context,
                        _CategoryPickerAction.newCategory,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
