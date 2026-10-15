import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/monthly_summary.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'categories_screen.dart';
import 'expenses_screen.dart';
import 'incomes_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _month = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<MonthlySummary> _summary;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _summary = AppDatabase.instance.summaryForMonth(_month);
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Monni',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatMonth(_month),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _BalanceCard(future: _summary),
                  const SizedBox(height: 28),
                  _HomeButton(
                    icon: Icons.arrow_downward_rounded,
                    label: 'Entradas',
                    description: 'Registar rendimentos',
                    color: AppTheme.income,
                    onTap: () => _open(const IncomesScreen()),
                  ),
                  const SizedBox(height: 14),
                  _HomeButton(
                    icon: Icons.arrow_upward_rounded,
                    label: 'Gastos',
                    description: 'Registar despesas',
                    color: AppTheme.expense,
                    onTap: () => _open(const ExpensesScreen()),
                  ),
                  const SizedBox(height: 14),
                  _HomeButton(
                    icon: Icons.pie_chart_rounded,
                    label: 'Resumo Mensal',
                    description: 'Saldo e gastos por categoria',
                    color: AppTheme.seed,
                    onTap: () => _open(const SummaryScreen()),
                  ),
                  const SizedBox(height: 14),
                  _HomeButton(
                    icon: Icons.category_rounded,
                    label: 'Categorias',
                    description: 'Criar, desativar e reativar',
                    color: AppTheme.seed,
                    onTap: () => _open(const CategoriesScreen()),
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

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.future});

  final Future<MonthlySummary> future;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<MonthlySummary>(
      future: future,
      builder: (context, snapshot) {
        final summary = snapshot.data ?? MonthlySummary.empty;
        final positive = summary.balance >= 0;
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary,
                scheme.primary.withValues(alpha: 0.75),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo do mês',
                style: TextStyle(
                  color: scheme.onPrimary.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatCurrency(summary.balance),
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MiniTotal(
                      label: 'Entradas',
                      value: summary.totalIncome,
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                  Expanded(
                    child: _MiniTotal(
                      label: 'Gastos',
                      value: summary.totalExpense,
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                ],
              ),
              if (!positive) ...[
                const SizedBox(height: 12),
                Text(
                  'Atenção: gastou mais do que recebeu.',
                  style: TextStyle(
                    color: scheme.onPrimary.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MiniTotal extends StatelessWidget {
  const _MiniTotal({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final double value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Row(
      children: [
        Icon(icon, size: 18, color: onPrimary.withValues(alpha: 0.85)),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: onPrimary.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatCurrency(value),
                  style: TextStyle(
                    color: onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeButton extends StatelessWidget {
  const _HomeButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(color: scheme.outline, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
