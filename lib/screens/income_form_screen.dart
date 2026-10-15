import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_database.dart';
import '../models/income.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class IncomeFormScreen extends StatefulWidget {
  const IncomeFormScreen({super.key, this.income});

  final Income? income;

  @override
  State<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends State<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final income = widget.income;
    _titleController = TextEditingController(text: income?.title ?? '');
    _amountController = TextEditingController(
      text: income == null ? '' : income.amount.toStringAsFixed(2),
    );
    _date = income?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
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

    final income = Income(
      id: widget.income?.id,
      title: _titleController.text.trim(),
      amount: parseAmount(_amountController.text)!,
      date: DateTime(_date.year, _date.month, _date.day),
    );

    final db = AppDatabase.instance;
    try {
      if (income.id == null) {
        await db.insertIncome(income);
      } else {
        await db.updateIncome(income);
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
    final isEditing = widget.income != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar entrada' : 'Nova entrada'),
      ),
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
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 60,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      hintText: 'Ex.: Salário, Freelance',
                      counterText: '',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Indique um título'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9.,]'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      prefixText: '\$ ',
                    ),
                    validator: (value) => parseAmount(value ?? '') == null
                        ? 'Indique um valor válido maior que zero'
                        : null,
                  ),
                  const SizedBox(height: 16),
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
