import '../data/models/finance_transaction.dart';
import 'text_utils.dart';

/// Builds CSV from rows already scoped to one authenticated user.
String buildTransactionsCsv(Iterable<FinanceTransaction> transactions) {
  final rows = transactions.toList()
    ..sort((a, b) {
      final date = a.date.compareTo(b.date);
      return date != 0 ? date : (a.id ?? 0).compareTo(b.id ?? 0);
    });
  final result = StringBuffer('\uFEFFid,date,type,category,amount,note\r\n');
  for (final row in rows) {
    result.write(
      '${row.id ?? ''},${row.date},${row.type.name},'
      '${csvEscape(row.category)},${row.amount},${csvEscape(row.note ?? '')}\r\n',
    );
  }
  return result.toString();
}
