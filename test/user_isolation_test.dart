import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pe_prm393_de190630/core/app_exception.dart';
import 'package:pe_prm393_de190630/data/app_database.dart';
import 'package:pe_prm393_de190630/data/models/budget.dart';
import 'package:pe_prm393_de190630/data/models/finance_transaction.dart';
import 'package:pe_prm393_de190630/data/repositories/budget_repository.dart';
import 'package:pe_prm393_de190630/data/repositories/transaction_repository.dart';
import 'package:pe_prm393_de190630/data/repositories/user_repository.dart';

void main() {
  late AppDatabase database;
  late TransactionRepository transactions;
  late BudgetRepository budgets;
  late int firstUser;
  late int secondUser;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    database = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    transactions = TransactionRepository(database);
    budgets = BudgetRepository(database);
    final users = UserRepository(database);
    firstUser = (await users.authenticate('demo1', 'Demo@123'))!.id;
    secondUser = (await users.authenticate('demo2', 'Demo@456'))!.id;
  });
  tearDown(() => database.close());

  FinanceTransaction entry(int owner, int amount) => FinanceTransaction(
    userId: owner,
    type: TxType.expense,
    amount: amount,
    category: 'Ăn uống',
    date: '2024-03-10',
    createdAt: '2024-03-10T12:00:00.000',
  );

  test(
    'one user cannot read, modify, delete, or aggregate another user rows',
    () async {
      final id = await transactions.insert(entry(firstUser, 50000));
      final original = (await transactions.getById(firstUser, id))!;
      expect(await transactions.getAll(secondUser), isEmpty);
      expect(await transactions.getById(secondUser, id), isNull);
      expect((await transactions.getTotals(secondUser)).expense, 0);
      expect(
        await transactions.getExpenseByCategory(
          secondUser,
          '2024-03-01',
          '2024-04-01',
        ),
        isEmpty,
      );
      await expectLater(
        transactions.update(original.copyWith(userId: secondUser, amount: 1)),
        throwsA(
          isA<AppException>().having(
            (error) => error.message,
            'message',
            'Không tìm thấy giao dịch',
          ),
        ),
      );
      await expectLater(
        transactions.delete(secondUser, id),
        throwsA(isA<AppException>()),
      );
      expect(
        (await transactions.getById(firstUser, id))!.toMap(),
        original.toMap(),
      );
      await transactions.insert(entry(secondUser, 70000));
      expect((await transactions.getTotals(firstUser)).expense, 50000);
      expect((await transactions.getTotals(secondUser)).expense, 70000);
    },
  );

  test(
    'budget ownership and foreign-key cascade preserve the other user',
    () async {
      await transactions.insert(entry(firstUser, 50000));
      await transactions.insert(entry(secondUser, 70000));
      await budgets.upsert(
        Budget(userId: firstUser, month: '2024-03', limitAmount: 100000),
      );
      expect(await budgets.getForMonth(secondUser, '2024-03'), isNull);
      await budgets.delete(secondUser, '2024-03');
      expect(
        (await budgets.getForMonth(firstUser, '2024-03'))!.limitAmount,
        100000,
      );
      await budgets.upsert(
        Budget(userId: secondUser, month: '2024-03', limitAmount: 200000),
      );
      await database.db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [firstUser],
      );
      expect(await transactions.getAll(firstUser), isEmpty);
      expect(await budgets.getForMonth(firstUser, '2024-03'), isNull);
      expect((await transactions.getAll(secondUser)), hasLength(1));
      expect(
        (await budgets.getForMonth(secondUser, '2024-03'))!.limitAmount,
        200000,
      );
    },
  );
}
