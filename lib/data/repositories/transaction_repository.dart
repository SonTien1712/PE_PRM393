import '../../core/app_exception.dart';
import '../../core/validators.dart';
import '../app_database.dart';
import '../models/category_total.dart';
import '../models/finance_transaction.dart';
import '../models/summary_totals.dart';
import 'repository_support.dart';

class TransactionRepository {
  TransactionRepository(this._database);

  final AppDatabase _database;

  Future<List<FinanceTransaction>> getAll(int userId) =>
      runDatabaseOperation(() async {
        final rows = await _database.db.query(
          'transactions',
          where: 'user_id = ?',
          whereArgs: [userId],
          orderBy: 'date DESC, id DESC',
        );
        return rows.map(FinanceTransaction.fromMap).toList();
      });

  Future<FinanceTransaction?> getById(int userId, int id) =>
      runDatabaseOperation(() async {
        final rows = await _database.db.query(
          'transactions',
          where: 'id = ? AND user_id = ?',
          whereArgs: [id, userId],
          limit: 1,
        );
        return rows.isEmpty ? null : FinanceTransaction.fromMap(rows.first);
      });

  Future<int> insert(FinanceTransaction transaction) =>
      runDatabaseOperation(() async {
        _validate(transaction);
        final values = transaction.toMap()..remove('id');
        return _database.db.insert('transactions', values);
      });

  Future<int> update(FinanceTransaction transaction) =>
      runDatabaseOperation(() async {
        _validate(transaction);
        if (transaction.id == null) {
          throw const AppException('Không tìm thấy giao dịch');
        }
        final changed = await _database.db.update(
          'transactions',
          {
            'type': transaction.type.name,
            'amount': transaction.amount,
            'category': transaction.category,
            'date': transaction.date,
            'note': transaction.note,
          },
          where: 'id = ? AND user_id = ?',
          whereArgs: [transaction.id, transaction.userId],
        );
        if (changed == 0) {
          throw const AppException('Không tìm thấy giao dịch');
        }
        return changed;
      });

  Future<int> delete(int userId, int id) => runDatabaseOperation(() async {
    final changed = await _database.db.delete(
      'transactions',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    if (changed == 0) throw const AppException('Không tìm thấy giao dịch');
    return changed;
  });

  Future<SummaryTotals> getTotals(
    int userId, {
    String? fromDate,
    String? toExclusive,
  }) => runDatabaseOperation(() async {
    final conditions = ['user_id = ?'];
    final arguments = <Object?>[userId];
    if (fromDate != null) {
      conditions.add('date >= ?');
      arguments.add(fromDate);
    }
    if (toExclusive != null) {
      conditions.add('date < ?');
      arguments.add(toExclusive);
    }
    final rows = await _database.db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount END), 0) AS income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount END), 0) AS expense
      FROM transactions
      WHERE ${conditions.join(' AND ')}
    ''', arguments);
    return SummaryTotals.fromMap(rows.first);
  });

  Future<List<CategoryTotal>> getExpenseByCategory(
    int userId,
    String fromDate,
    String toExclusive,
  ) => runDatabaseOperation(() async {
    final rows = await _database.db.rawQuery(
      '''
      SELECT category, SUM(amount) AS total
      FROM transactions
      WHERE user_id = ? AND type = 'expense' AND date >= ? AND date < ?
      GROUP BY category ORDER BY total DESC, category ASC
    ''',
      [userId, fromDate, toExclusive],
    );
    return rows.map(CategoryTotal.fromMap).toList();
  });

  void _validate(FinanceTransaction transaction) {
    final error =
        validateAmount(transaction.amount.toString()) ??
        validateCategory(transaction.category, transaction.type) ??
        validateDate(parseStorageDate(transaction.date)) ??
        validateNote(transaction.note);
    if (error != null) throw AppException(error);
  }
}
