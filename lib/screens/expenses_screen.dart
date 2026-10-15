import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/category_store.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/dialog_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/month_selector.dart';
import 'expense_form_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<Expense> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await AppDatabase.instance.expensesForMonth(_month);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _openForm([Expense? expense]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ExpenseFormScreen(expense: expense)),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(Expense expense) async {
    await AppDatabase.instance.deleteExpense(expense.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gasto eliminado.')),
    );
    await _load();
  }

  double get _total => _items.fold(0, (sum, e) => sum + e.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo gasto'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Column(
                    children: [
                      MonthSelector(
                        month: _month,
                        onChanged: (m) {
                          setState(() => _month = m);
                          _load();
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total do mês'),
                          Text(
                            formatCurrency(_total),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppTheme.expense,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? EmptyState(
                              icon: Icons.error_outline_rounded,
                              message: 'Não foi possível carregar os dados.\n'
                                  '$_error',
                            )
                          : _items.isEmpty
                          ? const EmptyState(
                              icon: Icons.receipt_long_outlined,
                              message: 'Sem gastos neste mês.\n'
                                  'Toque em "Novo gasto" para começar.',
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 96),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final expense = _items[index];
                                return _ExpenseTile(
                                  expense: expense,
                                  onTap: () => _openForm(expense),
                                  onDelete: () => _delete(expense),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.onTap,
    required this.onDelete,
  });

  final Expense expense;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Future<bool> _confirm(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: DialogHeader(
              title: 'Eliminar gasto?',
              onClose: () => Navigator.pop(context, false),
            ),
            content: Text(
              '${categoryByName(expense.category).name} · '
              '${formatCurrency(expense.amount)}',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final category = categoryByName(expense.category);
    final description = expense.description?.trim();
    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.expense.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppTheme.expense),
      ),
      confirmDismiss: (_) => _confirm(context),
      onDismissed: (_) => onDelete(),
      child: AppCard(
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
          subtitle: Text(
            description == null || description.isEmpty
                ? formatDate(expense.date)
                : '${formatDate(expense.date)} · $description',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatCurrency(expense.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.expense,
                ),
              ),
              IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppTheme.expense,
                onPressed: () async {
                  if (await _confirm(context)) onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
