import '../../core/app_exception.dart';
import '../../core/validators.dart';
import '../app_database.dart';
import '../models/budget.dart';
import 'repository_support.dart';

class BudgetRepository {
  BudgetRepository(this._database);

  final AppDatabase _database;

  Future<Budget?> getForMonth(int userId, String month) =>
      runDatabaseOperation(() async {
        final rows = await _database.db.query(
          'budgets',
          where: 'user_id = ? AND month = ?',
          whereArgs: [userId, month],
          limit: 1,
        );
        return rows.isEmpty ? null : Budget.fromMap(rows.first);
      });

  Future<void> upsert(Budget budget) => runDatabaseOperation(() async {
    final error = validateBudgetLimit(budget.limitAmount.toString());
    if (error != null) throw AppException(error);
    if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(budget.month)) {
      throw const AppException('Tháng không hợp lệ');
    }
    await _database.db.transaction((transaction) async {
      final changed = await transaction.update(
        'budgets',
        {'limit_amount': budget.limitAmount},
        where: 'user_id = ? AND month = ?',
        whereArgs: [budget.userId, budget.month],
      );
      if (changed == 0) {
        final values = budget.toMap()..remove('id');
        await transaction.insert('budgets', values);
      }
    });
  });

  Future<void> delete(int userId, String month) =>
      runDatabaseOperation(() async {
        await _database.db.delete(
          'budgets',
          where: 'user_id = ? AND month = ?',
          whereArgs: [userId, month],
        );
      });
}
