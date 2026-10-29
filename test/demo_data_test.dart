import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pe_prm393_de190630/core/budget_alert_calculator.dart';
import 'package:pe_prm393_de190630/core/month_utils.dart';
import 'package:pe_prm393_de190630/core/validators.dart';
import 'package:pe_prm393_de190630/data/app_database.dart';
import 'package:pe_prm393_de190630/data/models/budget_alert.dart';
import 'package:pe_prm393_de190630/data/models/finance_transaction.dart';
import 'package:pe_prm393_de190630/data/repositories/transaction_repository.dart';
import 'package:pe_prm393_de190630/data/repositories/user_repository.dart';

import '../tool/demo_dataset.dart';
import '../tool/demo_seed_support.dart';

void main() {
  final asOf = DateTime(2026, 10, 29);
  setUpAll(sqfliteFfiInit);

  Future<AppDatabase> open() =>
      AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);

  test(
    'demo dates remain valid on day one and across year/leap boundaries',
    () {
      for (final today in [asOf, DateTime(2026, 1, 1), DateTime(2028, 3, 1)]) {
        final accounts = buildDemoDataset(today);
        expect(accounts.map((a) => a.transactions.length), [35, 4, 0]);
        for (final account in accounts) {
          for (final row in account.transactions) {
            expect(
              validateDate(parseStorageDate(row.date), today: today),
              isNull,
            );
            expect(validateCategory(row.category, row.type), isNull);
            expect(validateNote(row.note), isNull);
          }
        }
        expect(accounts.first.budgets.first.month, monthKey(today));
      }
    },
  );

  test(
    'seed authenticates through the real repository and preserves old data',
    () async {
      final database = await open();
      addTearDown(database.close);
      final rows = TransactionRepository(database);
      await rows.insert(
        FinanceTransaction(
          userId: 1,
          type: TxType.income,
          amount: 123456,
          category: 'Lương',
          date: '2026-01-01',
          note: 'Dữ liệu cũ',
          createdAt: '2026-01-01T09:00:00',
        ),
      );
      final before = await database.db.query(
        'transactions',
        where: 'user_id = ?',
        whereArgs: [1],
      );
      final changes = await seedDemoData(database.db, asOf);
      expect(changes.map((r) => r['status']), everyElement('created'));
      expect(
        await database.db.query(
          'transactions',
          where: 'user_id = ?',
          whereArgs: [1],
        ),
        before,
      );
      final users = UserRepository(database);
      final presenter = (await users.authenticate(
        demoUsernames.first,
        demoPassword,
      ))!;
      expect((await rows.getAll(presenter.id)), hasLength(35));
      final totals = await rows.getTotals(presenter.id);
      expect(
        [totals.income, totals.expense, totals.balance],
        [57500000, 28300000, 29200000],
      );
      final current = await rows.getTotals(
        presenter.id,
        fromDate: '2026-10-01',
        toExclusive: '2026-11-01',
      );
      expect([current.income, current.expense], [21000000, 7900000]);
      final other = (await users.authenticate(demoUsernames[1], demoPassword))!;
      expect((await rows.getTotals(other.id)).balance, -750000);
      final empty = (await users.authenticate(demoUsernames[2], demoPassword))!;
      expect(await rows.getAll(empty.id), isEmpty);
      expect(await database.db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    },
  );

  test(
    'running again neither duplicates nor overwrites an edited demo row',
    () async {
      final database = await open();
      addTearDown(database.close);
      await seedDemoData(database.db, asOf);
      final presenter = (await UserRepository(database)
          .authenticate(demoUsernames.first, demoPassword))!;
      final rows = TransactionRepository(database);
      final changed = (await rows.getAll(presenter.id)).first
          .copyWith(amount: 777777, note: 'Đã sửa khi demo');
      await rows.update(changed);
      final usersBefore = await database.db.query('users');
      final rowsBefore = await database.db.query('transactions');
      final budgetsBefore = await database.db.query('budgets');
      final result = await seedDemoData(database.db, asOf);
      expect(result.map((r) => r['status']), everyElement('kept_existing'));
      expect(await database.db.query('users'), usersBefore);
      expect(await database.db.query('transactions'), rowsBefore);
      expect(await database.db.query('budgets'), budgetsBefore);
    },
  );

  test(
    'a reserved username collision rolls back all new demo accounts',
    () async {
      final database = await open();
      addTearDown(database.close);
      await UserRepository(database).register(
        username: demoUsernames[1],
        password: 'Existing123',
        displayName: 'Đã tồn tại',
      );
      final usersBefore = await database.db.query('users');
      await expectLater(
        seedDemoData(database.db, asOf),
        throwsA(isA<StateError>()),
      );
      expect(await database.db.query('users'), usersBefore);
      expect(await database.db.query('transactions'), isEmpty);
      expect(await database.db.query('budgets'), isEmpty);
    },
  );

  test(
    'SQLite backup reopens as the original snapshot, before demo insertion',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'finance_demo_backup_test_',
      );
      final database = await open();
      try {
        final backupPath = await backupDemoDatabase(database.db, directory);
        await seedDemoData(database.db, asOf);
        final backup = await AppDatabase.open(
          path: backupPath,
          factory: databaseFactoryFfi,
        );
        try {
          expect(await backup.db.query('users'), hasLength(2));
          expect(await backup.db.query('transactions'), isEmpty);
          await validateDemoDatabase(backup.db);
        } finally {
          await backup.close();
        }
      } finally {
        await database.close();
        if (!path.isWithin(
              Directory.systemTemp.absolute.path,
              directory.absolute.path,
            ) ||
            !path
                .basename(directory.path)
                .startsWith('finance_demo_backup_test_')) {
          throw StateError('Refusing unsafe cleanup.');
        }
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'presentation starts at 79%, then alerts at 80% and above 100%',
    () async {
      final database = await open();
      addTearDown(database.close);
      await seedDemoData(database.db, asOf);
      final presenter = (await demoDatabaseSummary(database.db)).first;
      final month = (presenter['months'] as List).first as Map;
      final spent = month['expense'] as int;
      final limit = month['limit_amount'] as int;
      expect(budgetLevel(spent, limit), isNull);
      expect(
        calculateBudgetAlert(
          beforeSpent: spent,
          afterSpent: spent + 100000,
          limit: limit,
        )!.level,
        BudgetAlertLevel.warning,
      );
      expect(
        calculateBudgetAlert(
          beforeSpent: 8000000,
          afterSpent: 8500000,
          limit: limit,
        ),
        isNull,
      );
      expect(
        calculateBudgetAlert(
          beforeSpent: 8500000,
          afterSpent: 10500000,
          limit: limit,
        )!.level,
        BudgetAlertLevel.exceeded,
      );
    },
  );
}
