import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_database.dart';
import '../data/category_store.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

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
    if (expense != null &&
        !_options.any((c) => c.name == expense.category)) {
      // A categoria do gasto em edição pode estar desativada.
      _options = [..._options, CategoryStore.instance.byName(expense.category)];
    }
    _category = expense?.category ??
        (_options.isEmpty ? '' : _options.first.name);
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
                  const Text(
                    'Categoria',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in _options)
                        ChoiceChip(
                          selected: _category == category.name,
                          onSelected: (_) =>
                              setState(() => _category = category.name),
                          avatar: Icon(
                            category.icon,
                            size: 18,
                            color: category.color,
                          ),
                          label: Text(category.name),
                          selectedColor: category.color.withValues(alpha: 0.18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                    ],
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
