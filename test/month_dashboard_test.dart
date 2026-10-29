import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pe_prm393_de190630/core/app_exception.dart';
import 'package:pe_prm393_de190630/core/month_utils.dart';
import 'package:pe_prm393_de190630/data/models/category_total.dart';
import 'package:pe_prm393_de190630/data/models/finance_transaction.dart';
import 'package:pe_prm393_de190630/data/models/summary_totals.dart';
import 'package:pe_prm393_de190630/providers/transaction_provider.dart';

import 'helpers/fakes.dart';

void main() {
  test('month ranges roll over December and leap years', () {
    expect(monthRange(DateTime(2024, 2)), ('2024-02-01', '2024-03-01'));
    expect(monthRange(DateTime(2026, 12)), ('2026-12-01', '2027-01-01'));
  });

  test(
    'selection reloads month data without changing all-time totals or filters',
    () async {
      final repository = _MonthlyRows();
      final provider = TransactionProvider(
        repository,
        FakeBudgets(),
        now: () => DateTime(2026, 10, 28),
      );
      addTearDown(provider.dispose);
      provider.setUser(1);
      await Future<void>.delayed(Duration.zero);
      expect(provider.monthTotals.expense, 300);
      expect(provider.monthBreakdown.single.total, 300);
      expect(provider.totals.expense, 500);
      provider.setSearch('Ăn uống');
      await provider.changeMonth(-1);
      expect(provider.selectedMonthKey, '2026-09');
      expect(provider.monthTotals.expense, 200);
      expect(provider.totals.expense, 500);
      expect(repository.allTimeReads, 1);
      expect(provider.searchQuery, 'Ăn uống');
      await provider.changeMonth(2);
      expect(provider.selectedMonthKey, '2026-09');
      await provider.changeMonth(1);
      expect(provider.canGoNextMonth, isFalse);
    },
  );

  for (final fails in [false, true]) {
    test(
      'late month ${fails ? 'error' : 'data'} cannot replace newer selection',
      () async {
        final repository = _MonthlyRows();
        final provider = TransactionProvider(
          repository,
          FakeBudgets(),
          now: () => DateTime(2026, 10, 28),
        );
        addTearDown(provider.dispose);
        provider.setUser(1);
        await Future<void>.delayed(Duration.zero);
        final gate = Completer<List<CategoryTotal>>();
        repository.september = gate;
        final old = provider.changeMonth(-1);
        await Future<void>.delayed(Duration.zero);
        await provider.changeMonth(-1);
        expect(provider.selectedMonthKey, '2026-08');
        expect(provider.hasMonthData, isTrue);
        if (fails) {
          gate.completeError(const AppException('Old month error'));
        } else {
          gate.complete(const [CategoryTotal(category: 'Khác', total: 999)]);
        }
        await old;
        expect(provider.monthTotals.expense, 0);
        expect(provider.monthBreakdown, isEmpty);
        expect(provider.errorMessage, isNull);
        expect(provider.isMonthLoading, isFalse);
      },
    );
  }
}

class _MonthlyRows extends FakeTransactions {
  _MonthlyRows()
    : super([
        for (final (month, amount) in [(9, 200), (10, 300)])
          FinanceTransaction(
            id: month,
            userId: 1,
            type: TxType.expense,
            amount: amount,
            category: 'Ăn uống',
            date: '${monthKey(DateTime(2026, month))}-01',
            createdAt: '2026-10-01T00:00:00',
          ),
      ]);
  int allTimeReads = 0;
  Completer<List<CategoryTotal>>? september;

  @override
  Future<SummaryTotals> getTotals(
    int userId, {
    String? fromDate,
    String? toExclusive,
  }) {
    if (fromDate == null) allTimeReads++;
    return super.getTotals(
      userId,
      fromDate: fromDate,
      toExclusive: toExclusive,
    );
  }

  @override
  Future<List<CategoryTotal>> getExpenseByCategory(
    int userId,
    String fromDate,
    String toExclusive,
  ) {
    if (fromDate == '2026-09-01' && september != null) return september!.future;
    return super.getExpenseByCategory(userId, fromDate, toExclusive);
  }
}
