import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Barra com setas para navegar entre meses.
class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.month,
    required this.onChanged,
  });

  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Mês anterior',
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () =>
                onChanged(DateTime(month.year, month.month - 1)),
          ),
          Expanded(
            child: Text(
              formatMonth(month),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Mês seguinte',
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () =>
                onChanged(DateTime(month.year, month.month + 1)),
          ),
        ],
      ),
    );
  }
}
