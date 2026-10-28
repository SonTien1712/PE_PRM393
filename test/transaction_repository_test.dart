import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pe_prm393_de190630/core/app_exception.dart';
import 'package:pe_prm393_de190630/core/constants.dart';
import 'package:pe_prm393_de190630/data/app_database.dart';
import 'package:pe_prm393_de190630/data/models/finance_transaction.dart';
import 'package:pe_prm393_de190630/data/repositories/transaction_repository.dart';
import 'package:pe_prm393_de190630/data/repositories/user_repository.dart';

void main() {
  late AppDatabase database;
  late TransactionRepository repository;
  late int userId;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    database = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    repository = TransactionRepository(database);
    userId = (await UserRepository(
      database,
    ).authenticate('demo1', 'Demo@123'))!.id;
  });
  tearDown(() => database.close());

  FinanceTransaction entry({
    TxType type = TxType.expense,
    int amount = 50000,
    String date = '2024-03-15',
    String? category,
  }) => FinanceTransaction(
    userId: userId,
    type: type,
    amount: amount,
    category: category ?? (type == TxType.expense ? 'Ăn uống' : 'Lương'),
    date: date,
    note: 'Bữa trưa',
    createdAt: '2024-03-15T10:00:00.000',
  );

  test(
    'CRUD persists fields, orders rows, and preserves immutable fields',
    () async {
      final transaction = entry();
      final id = await repository.insert(transaction);
      final newerId = await repository.insert(entry(date: '2024-03-16'));
      expect((await repository.getAll(userId)).map((row) => row.id), [
        newerId,
        id,
      ]);
      final saved = (await repository.getById(userId, id))!;
      expect(saved.toMap(), {...transaction.toMap(), 'id': id});
      final updated = saved.copyWith(
        type: TxType.income,
        category: 'Thưởng',
        amount: 200000,
        note: null,
        createdAt: '2099-01-01T00:00:00.000',
      );
      expect(await repository.update(updated), 1);
      final after = (await repository.getById(userId, id))!;
      expect(after.type, TxType.income);
      expect(after.amount, 200000);
      expect(after.note, isNull);
      expect(after.userId, userId);
      expect(after.createdAt, transaction.createdAt);
      expect(await repository.delete(userId, id), 1);
      expect(await repository.getById(userId, id), isNull);
      expect((await repository.getAll(userId)), hasLength(1));
      await expectLater(
        repository.delete(userId, id),
        throwsA(isA<AppException>()),
      );
      await expectLater(repository.update(saved), throwsA(isA<AppException>()));
    },
  );

  test(
    'SQL totals and category breakdown use a half-open month range',
    () async {
      expect((await repository.getTotals(userId)).balance, 0);
      await repository.insert(
        entry(type: TxType.income, amount: 1000000, date: '2024-03-01'),
      );
      await repository.insert(entry(amount: 50000, date: '2024-03-15'));
      await repository.insert(
        entry(amount: 25000, category: 'Đi lại', date: '2024-03-31'),
      );
      await repository.insert(entry(amount: 10000, date: '2024-02-29'));
      await repository.insert(entry(amount: 20000, date: '2024-04-01'));
      final all = await repository.getTotals(userId);
      expect(all.income, 1000000);
      expect(all.expense, 105000);
      expect(all.balance, 895000);
      final march = await repository.getTotals(
        userId,
        fromDate: '2024-03-01',
        toExclusive: '2024-04-01',
      );
      expect(march.income, 1000000);
      expect(march.expense, 75000);
      final breakdown = await repository.getExpenseByCategory(
        userId,
        '2024-03-01',
        '2024-04-01',
      );
      expect(breakdown.map((row) => row.category), ['Ăn uống', 'Đi lại']);
      expect(breakdown.map((row) => row.total), [50000, 25000]);
    },
  );

  test('repository rejects invalid category, date, note, and amount', () async {
    for (final transaction in [
      entry(amount: 0),
      entry(amount: maxAmount + 1),
      entry(type: TxType.income, category: 'Ăn uống'),
      entry(date: '2024-02-30'),
      entry(date: '2999-01-01'),
      entry().copyWith(note: 'x' * 201),
    ]) {
      await expectLater(
        repository.insert(transaction),
        throwsA(isA<AppException>()),
      );
    }
    expect(await repository.getAll(userId), isEmpty);
  });

  test(
    'SQLite CHECK constraints reject zero and over-maximum money independently',
    () async {
      for (final invalid in [0, maxAmount + 1]) {
        await expectLater(
          database.db.insert('transactions', entry(amount: invalid).toMap()),
          throwsA(isA<DatabaseException>()),
        );
        await expectLater(
          database.db.insert('budgets', {
            'user_id': userId,
            'month': '2024-03',
            'limit_amount': invalid,
          }),
          throwsA(isA<DatabaseException>()),
        );
      }
      final maximumId = await repository.insert(entry(amount: maxAmount));
      expect((await repository.getById(userId, maximumId))!.amount, maxAmount);
    },
  );

  test(
    'seed authentication is case insensitive and exposes no password in model',
    () async {
      final users = UserRepository(database);
      expect((await users.authenticate('  DEMO1  ', 'Demo@123'))!.id, userId);
      expect(await users.authenticate('demo1', 'wrong-password'), isNull);
      final user = await users.findById(userId);
      expect(
        user!.toMap().keys,
        unorderedEquals(['id', 'username', 'display_name']),
      );
    },
  );
}
