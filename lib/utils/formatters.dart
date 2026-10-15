import 'package:intl/intl.dart';

const _locale = 'pt_PT';

final NumberFormat _currency =
    NumberFormat.currency(locale: _locale, symbol: '\$', decimalDigits: 2);
final DateFormat _shortDate = DateFormat('dd/MM/yyyy', _locale);
final DateFormat _monthYear = DateFormat('MMMM yyyy', _locale);

String formatCurrency(double value) => _currency.format(value);

String formatDate(DateTime date) => _shortDate.format(date);

String formatMonth(DateTime date) {
  final text = _monthYear.format(date);
  return text[0].toUpperCase() + text.substring(1);
}

String formatPercent(double value) =>
    '${value.toStringAsFixed(value >= 10 ? 0 : 1)}%';

/// Converte texto introduzido pelo utilizador ("12,50" ou "12.50") em double.
double? parseAmount(String input) {
  final normalized = input.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  final value = double.tryParse(normalized);
  if (value == null || value <= 0 || !value.isFinite) return null;
  return double.parse(value.toStringAsFixed(2));
}
