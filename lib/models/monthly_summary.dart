/// Totais de um mês, já agregados pela base de dados.
class MonthlySummary {
  const MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.byCategory,
  });

  final double totalIncome;
  final double totalExpense;

  /// Categoria -> total gasto, ordenado por valor decrescente.
  final Map<String, double> byCategory;

  double get balance => totalIncome - totalExpense;

  double percentageOf(String category) {
    if (totalExpense <= 0) return 0;
    return (byCategory[category] ?? 0) / totalExpense * 100;
  }

  static const empty = MonthlySummary(
    totalIncome: 0,
    totalExpense: 0,
    byCategory: {},
  );
}
