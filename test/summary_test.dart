import 'package:flutter_test/flutter_test.dart';
import 'package:monni/models/monthly_summary.dart';
import 'package:monni/utils/formatters.dart';

void main() {
  group('parseAmount', () {
    test('aceita vírgula e ponto decimal', () {
      expect(parseAmount('12,50'), 12.5);
      expect(parseAmount('12.50'), 12.5);
      expect(parseAmount(' 1 000,05 '), 1000.05);
    });

    test('rejeita valores inválidos ou não positivos', () {
      expect(parseAmount(''), isNull);
      expect(parseAmount('abc'), isNull);
      expect(parseAmount('0'), isNull);
      expect(parseAmount('-5'), isNull);
    });
  });

  group('MonthlySummary', () {
    const summary = MonthlySummary(
      totalIncome: 1000,
      totalExpense: 400,
      byCategory: {'Alimentação': 300, 'Transportes': 100},
    );

    test('saldo é entradas menos gastos', () {
      expect(summary.balance, 600);
    });

    test('percentagem por categoria', () {
      expect(summary.percentageOf('Alimentação'), 75);
      expect(summary.percentageOf('Transportes'), 25);
      expect(summary.percentageOf('Lazer'), 0);
    });

    test('sem gastos a percentagem é zero', () {
      expect(MonthlySummary.empty.percentageOf('Alimentação'), 0);
    });
  });
}
