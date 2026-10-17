import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/category_store.dart';
import '../models/monthly_summary.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/month_selector.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  MonthlySummary _summary = MonthlySummary.empty;
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
      final summary = await AppDatabase.instance.summaryForMonth(_month);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _summary = MonthlySummary.empty;
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _summary.totalIncome > 0 || _summary.totalExpense > 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Resumo Mensal')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    children: [
                      MonthSelector(
                        month: _month,
                        onChanged: (m) {
                          setState(() => _month = m);
                          _load();
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: EmptyState(
                            icon: Icons.error_outline_rounded,
                            message: 'Não foi possível carregar os dados.\n'
                                '$_error',
                          ),
                        )
                      else if (!hasData)
                        const Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: EmptyState(
                            icon: Icons.insights_outlined,
                            message: 'Ainda não há movimentos neste mês.',
                          ),
                        )
                      else ...[
                        _TotalsCard(summary: _summary),
                        const SizedBox(height: 20),
                        if (_summary.byCategory.isEmpty)
                          const _SectionCard(
                            title: 'Gastos por categoria',
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text('Sem gastos registados.'),
                              ),
                            ),
                          )
                        else ...[
                          _SectionCard(
                            title: 'Distribuição dos gastos',
                            child: _CategoryPieChart(summary: _summary),
                          ),
                          const SizedBox(height: 20),
                          _SectionCard(
                            title: 'Gastos por categoria',
                            child: _CategoryBreakdown(summary: _summary),
                          ),
                        ],
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.summary});

  final MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final positive = summary.balance >= 0;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TotalRow(
              label: 'Total de entradas',
              value: summary.totalIncome,
              color: AppTheme.income,
              icon: Icons.arrow_downward_rounded,
            ),
            const SizedBox(height: 14),
            _TotalRow(
              label: 'Total de gastos',
              value: summary.totalExpense,
              color: AppTheme.expense,
              icon: Icons.arrow_upward_rounded,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: scheme.outlineVariant),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saldo final',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(summary.balance),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: positive ? AppTheme.income : AppTheme.expense,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatPercent(summary.balancePercentageOfIncome),
                      style: TextStyle(color: scheme.outline),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(
          formatCurrency(value),
          style: TextStyle(fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _CategoryPieChart extends StatefulWidget {
  const _CategoryPieChart({required this.summary});

  final MonthlySummary summary;

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final entries = widget.summary.byCategory.entries.toList();
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 54,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touchedIndex = event.isInterestedForInteractions &&
                            response?.touchedSection != null
                        ? response!.touchedSection!.touchedSectionIndex
                        : -1;
                  });
                },
              ),
              sections: [
                for (var i = 0; i < entries.length; i++)
                  _section(
                      entries[i].key, entries[i].value, i == _touchedIndex),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final entry in entries)
              _LegendDot(
                color: categoryByName(entry.key).color,
                label: entry.key,
              ),
          ],
        ),
      ],
    );
  }

  PieChartSectionData _section(String name, double value, bool touched) {
    final percent = widget.summary.percentageOf(name);
    return PieChartSectionData(
      value: value,
      color: categoryByName(name).color,
      radius: touched ? 62 : 54,
      title: percent >= 6 ? formatPercent(percent) : '',
      titleStyle: TextStyle(
        fontSize: touched ? 14 : 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.summary});

  final MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = summary.byCategory.entries.toList();
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(height: 18),
          Builder(
            builder: (context) {
              final category = categoryByName(entries[i].key);
              final percent = summary.percentageOf(entries[i].key);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(category.icon, size: 18, color: category.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        formatCurrency(entries[i].value),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 48,
                        child: Text(
                          formatPercent(percent),
                          textAlign: TextAlign.right,
                          style: TextStyle(color: scheme.outline),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (percent / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: category.color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(category.color),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}
