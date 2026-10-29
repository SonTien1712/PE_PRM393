import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pe_prm393_de190630/core/app_exception.dart';
import 'package:pe_prm393_de190630/core/budget_alert_calculator.dart';
import 'package:pe_prm393_de190630/core/constants.dart';
import 'package:pe_prm393_de190630/data/app_database.dart';
import 'package:pe_prm393_de190630/data/models/budget.dart';
import 'package:pe_prm393_de190630/data/models/budget_alert.dart';
import 'package:pe_prm393_de190630/data/models/finance_transaction.dart';
import 'package:pe_prm393_de190630/data/repositories/budget_repository.dart';
import 'package:pe_prm393_de190630/providers/transaction_provider.dart';

import 'helpers/fakes.dart';

void main() {
  test(
    'thresholds include exactly 80% and 100%, but exceeded is strictly greater',
    () {
      expect(budgetLevel(799, 1000), isNull);
      expect(budgetLevel(800, 1000), BudgetAlertLevel.warning);
      expect(budgetLevel(1000, 1000), BudgetAlertLevel.warning);
      expect(budgetLevel(1001, 1000), BudgetAlertLevel.exceeded);
      expect(budgetLevel(1000, 0), isNull);
    },
  );

  test('only upward level transitions alert', () {
    expect(
      calculateBudgetAlert(
        beforeSpent: 799,
        afterSpent: 800,
        limit: 1000,
      )?.level,
      BudgetAlertLevel.warning,
    );
    expect(
      calculateBudgetAlert(
        beforeSpent: 900,
        afterSpent: 1001,
        limit: 1000,
      )?.level,
      BudgetAlertLevel.exceeded,
    );
    expect(
      calculateBudgetAlert(
        beforeSpent: 0,
        afterSpent: 1500,
        limit: 1000,
      )?.level,
      BudgetAlertLevel.exceeded,
    );
    expect(
      calculateBudgetAlert(beforeSpent: 800, afterSpent: 900, limit: 1000),
      isNull,
    );
    expect(
      calculateBudgetAlert(beforeSpent: 1100, afterSpent: 1500, limit: 1000),
      isNull,
    );
    expect(
      calculateBudgetAlert(beforeSpent: 1100, afterSpent: 700, limit: 1000),
      isNull,
    );
  });

  group('real SQLite budgets', () {
    late AppDatabase database;
    late BudgetRepository repository;
    setUpAll(sqfliteFfiInit);
    setUp(() async {
      database = await AppDatabase.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      repository = BudgetRepository(database);
    });
    tearDown(() => database.close());

    test(
      'upsert preserves id, separates users and months, delete is scoped',
      () async {
        await repository.upsert(
          const Budget(userId: 1, month: '2026-10', limitAmount: 1000),
        );
        final first = (await repository.getForMonth(1, '2026-10'))!;
        await repository.upsert(
          const Budget(userId: 1, month: '2026-10', limitAmount: 2000),
        );
        final updated = (await repository.getForMonth(1, '2026-10'))!;
        expect(updated.id, first.id);
        expect(updated.limitAmount, 2000);
        expect(await repository.getForMonth(2, '2026-10'), isNull);
        expect(await repository.getForMonth(1, '2026-09'), isNull);
        await repository.delete(2, '2026-10');
        expect(await repository.getForMonth(1, '2026-10'), isNotNull);
        await repository.delete(1, '2026-10');
        expect(await repository.getForMonth(1, '2026-10'), isNull);
      },
    );

    test('repository and schema both enforce budget bounds', () async {
      for (final value in [0, -1, maxAmount + 1]) {
        await expectLater(
          repository.upsert(
            Budget(userId: 1, month: '2026-10', limitAmount: value),
          ),
          throwsA(isA<AppException>()),
        );
        await expectLater(
          database.db.insert('budgets', {
            'user_id': 1,
            'month': '2026-10',
            'limit_amount': value,
          }),
          throwsA(isA<DatabaseException>()),
        );
      }
      await repository.upsert(
        const Budget(userId: 1, month: '2026-10', limitAmount: maxAmount),
      );
      expect(
        (await repository.getForMonth(1, '2026-10'))!.limitAmount,
        maxAmount,
      );
    });
  });

  group('budget orchestration', () {
    late FakeTransactions rows;
    late FakeBudgets budgets;
    late TransactionProvider provider;
    setUp(() async {
      rows = FakeTransactions();
      budgets = FakeBudgets();
      budgets.rows['1:2026-10'] = const Budget(
        userId: 1,
        month: '2026-10',
        limitAmount: 1000,
      );
      provider = TransactionProvider(
        rows,
        budgets,
        now: () => DateTime(2026, 10, 28),
      );
      provider.setUser(1);
      await Future<void>.delayed(Duration.zero);
    });
    tearDown(() => provider.dispose());

    FinanceTransaction expense(int amount, {String date = '2026-10-01'}) =>
        FinanceTransaction(
          userId: 999,
          type: TxType.expense,
          amount: amount,
          category: 'Ăn uống',
          date: date,
          createdAt: '2026-10-01T00:00:00',
        );

    test('add and edit compare actual month expense, independent of selected month', () async {
      await provider.changeMonth(-1);
      expect(
        (await provider.add(expense(800))).alert?.level,
        BudgetAlertLevel.warning,
      );
      expect((await provider.add(expense(100))).alert, isNull);
      expect(
        (await provider.add(expense(200))).alert?.level,
        BudgetAlertLevel.exceeded,
      );
      // Editing an existing expense subtracts its original amount first.
      expect(
        (await provider.update(rows.rows.first.copyWith(amount: 700))).alert,
        isNull,
      );
      expect(provider.selectedMonthKey, '2026-09');
      expect(provider.monthTotals.expense, 0);
      expect(provider.totals.expense, 1000);
    });

    test('moving an expense into the budget month and changing income to expense alert', () async {
      await provider.add(expense(900, date: '2026-09-01'));
      final moved = rows.rows.single.copyWith(date: '2026-10-01');
      expect(
        (await provider.update(moved)).alert?.level,
        BudgetAlertLevel.warning,
      );
      final income = expense(200)
          .copyWith(type: TxType.income, category: 'Lương');
      expect((await provider.add(income)).alert, isNull);
      final changed = rows.rows.last.copyWith(
        type: TxType.expense,
        category: 'Ăn uống',
      );
      expect(
        (await provider.update(changed)).alert?.level,
        BudgetAlertLevel.exceeded,
      );
    });

    test(
      'optional alert read failure never blocks the committed transaction',
      () async {
        budgets.failReads = true;
        final result = await provider.add(expense(800));
        expect(result.ok, isTrue);
        expect(result.alert, isNull);
        expect(rows.insertCalls, 1);
        expect(result.message, contains('Đã lưu giao dịch'));
      },
    );

    test('budget commit plus refresh failure completes normally with a read warning', () async {
      budgets.failReadsAfterWrite = true;
      await provider.saveBudget(2000);
      expect(budgets.writes, 1);
      expect(budgets.rows['1:2026-10']!.limitAmount, 2000);
      expect(provider.monthBudget!.limitAmount, 2000);
      expect(provider.errorMessage, contains('Đã lưu ngân sách'));
      expect(provider.needsRefresh, isTrue);
      budgets.failReads = false;
      await provider.refresh();
      await provider.removeBudget();
      expect(provider.monthBudget, isNull);
      expect(budgets.rows, isEmpty);
    });
  });
}
