import 'dart:async';

import 'package:pe_prm393_de190630/core/app_exception.dart';
import 'package:pe_prm393_de190630/data/models/app_user.dart';
import 'package:pe_prm393_de190630/data/models/finance_transaction.dart';
import 'package:pe_prm393_de190630/data/models/summary_totals.dart';
import 'package:pe_prm393_de190630/data/repositories/budget_repository.dart';
import 'package:pe_prm393_de190630/data/repositories/transaction_repository.dart';
import 'package:pe_prm393_de190630/data/repositories/user_repository.dart';
import 'package:pe_prm393_de190630/data/session_storage.dart';

class FakeUsers implements UserRepository {
  static const users = [
    AppUser(id: 1, username: 'demo1', displayName: 'Demo 1'),
    AppUser(id: 2, username: 'demo2', displayName: 'Demo 2'),
  ];

  @override
  Future<AppUser?> findById(int id) async {
    for (final user in users) {
      if (user.id == id) return user;
    }
    return null;
  }

  @override
  Future<AppUser?> authenticate(String username, String password) async {
    for (final user in users) {
      final expected = user.id == 1 ? 'Demo@123' : 'Demo@456';
      if (user.username == username.trim().toLowerCase() &&
          password == expected) {
        return user;
      }
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeBudgets implements BudgetRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSession implements SessionStorage {
  FakeSession(this.data);
  SessionData? data;
  bool failRead = false;
  int clearCalls = 0;

  @override
  Future<SessionData?> read() async {
    if (failRead) throw StateError('Injected session read failure');
    return data;
  }

  @override
  Future<void> save(int userId) async {
    data = SessionData(userId: userId, createdAt: DateTime.now());
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    data = null;
  }
}

class FakeTransactions implements TransactionRepository {
  FakeTransactions([Iterable<FinanceTransaction> initial = const []])
    : rows = [...initial];

  final List<FinanceTransaction> rows;
  Completer<void>? insertGate;
  bool failReads = false;
  bool failReadsAfterInsert = false;
  int insertCalls = 0;

  @override
  Future<List<FinanceTransaction>> getAll(int userId) async {
    if (failReads) {
      throw const AppException('Lỗi cơ sở dữ liệu. Vui lòng thử lại.');
    }
    final result = rows.where((row) => row.userId == userId).toList();
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  @override
  Future<SummaryTotals> getTotals(
    int userId, {
    String? fromDate,
    String? toExclusive,
  }) async {
    var income = 0;
    var expense = 0;
    for (final row in await getAll(userId)) {
      if (fromDate != null && row.date.compareTo(fromDate) < 0) continue;
      if (toExclusive != null && row.date.compareTo(toExclusive) >= 0) continue;
      if (row.type == TxType.income) {
        income += row.amount;
      } else {
        expense += row.amount;
      }
    }
    return SummaryTotals(income: income, expense: expense);
  }

  @override
  Future<int> insert(FinanceTransaction transaction) async {
    insertCalls++;
    if (insertGate != null) await insertGate!.future;
    final id =
        rows.fold(0, (max, row) => (row.id ?? 0) > max ? row.id! : max) + 1;
    rows.add(transaction.copyWith(id: id));
    if (failReadsAfterInsert) failReads = true;
    return id;
  }

  @override
  Future<int> update(FinanceTransaction transaction) async {
    final index = rows.indexWhere(
      (row) => row.id == transaction.id && row.userId == transaction.userId,
    );
    if (index < 0) throw const AppException('Không tìm thấy giao dịch');
    rows[index] = transaction.copyWith(createdAt: rows[index].createdAt);
    return 1;
  }

  @override
  Future<int> delete(int userId, int id) async {
    final index = rows.indexWhere(
      (row) => row.id == id && row.userId == userId,
    );
    if (index < 0) throw const AppException('Không tìm thấy giao dịch');
    rows.removeAt(index);
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
