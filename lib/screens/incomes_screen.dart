import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/income.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/dialog_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/month_selector.dart';
import 'income_form_screen.dart';

class IncomesScreen extends StatefulWidget {
  const IncomesScreen({super.key});

  @override
  State<IncomesScreen> createState() => _IncomesScreenState();
}

class _IncomesScreenState extends State<IncomesScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<Income> _items = const [];
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
      final items = await AppDatabase.instance.incomesForMonth(_month);
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

  Future<void> _openForm([Income? income]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => IncomeFormScreen(income: income)),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(Income income) async {
    await AppDatabase.instance.deleteIncome(income.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Entrada eliminada.')));
    await _load();
  }

  double get _total => _items.fold(0, (sum, e) => sum + e.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entradas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova entrada'),
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
                              color: AppTheme.income,
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
                          icon: Icons.savings_outlined,
                          message:
                              'Sem entradas neste mês.\n'
                              'Toque em "Nova entrada" para começar.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final income = _items[index];
                            return _IncomeTile(
                              income: income,
                              onTap: () => _openForm(income),
                              onDelete: () => _delete(income),
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

class _IncomeTile extends StatelessWidget {
  const _IncomeTile({
    required this.income,
    required this.onTap,
    required this.onDelete,
  });

  final Income income;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Future<bool> _confirm(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: DialogHeader(
              title: 'Eliminar entrada?',
              onClose: () => Navigator.pop(context, false),
            ),
            content: Text('"${income.title}" será removida.'),
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
    return Dismissible(
      key: ValueKey(income.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.expense.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppTheme.expense,
        ),
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
              color: AppTheme.income.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_downward_rounded,
              color: AppTheme.income,
            ),
          ),
          title: Text(
            income.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(formatDate(income.date)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatCurrency(income.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.income,
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
