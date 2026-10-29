import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pe_prm393_de190630/core/app_exception.dart';
import 'package:pe_prm393_de190630/data/models/finance_transaction.dart';
import 'package:pe_prm393_de190630/data/models/category_total.dart';
import 'package:pe_prm393_de190630/data/models/summary_totals.dart';
import 'package:pe_prm393_de190630/data/repositories/transaction_repository.dart';
import 'package:pe_prm393_de190630/providers/transaction_provider.dart';

import 'helpers/fakes.dart';

void main() {
  late _TransactionRepository repository;
  late TransactionProvider provider;

  setUp(() {
    repository = _TransactionRepository();
    provider = TransactionProvider(repository, _BudgetRepository());
  });

  tearDown(() => provider.dispose());

  test('setUser clears silently and then loads SQL totals', () async {
    repository.rows[1] = [_row(1, 1)];
    var notifications = 0;
    provider.addListener(() => notifications++);

    provider.setUser(1);
    expect(notifications, 0);
    expect(provider.all, isEmpty);
    expect(provider.hasLoaded, isFalse);
    await _flush();

    expect(provider.all.single.userId, 1);
    expect(provider.totals.income, 9000);
    expect(provider.totals.expense, 4000);
    expect(provider.hasLoaded, isTrue);
    expect(provider.lastRefreshSucceeded, isTrue);
    expect(repository.totalOwners, [1]);
    expect(() => provider.all.add(_row(2, 1)), throwsUnsupportedError);
  });

  for (final failOldRead in [false, true]) {
    test(
      'old-user ${failOldRead ? 'error' : 'rows'} cannot alter new state',
      () async {
        final pending = Completer<List<FinanceTransaction>>();
        repository.read = (userId) async =>
            userId == 1 ? pending.future : [_row(2, 2)];
        provider.setUser(1);
        await _flush();
        provider.setSearch('old query');
        provider.setTypeFilter(TxType.expense);
        provider.setSort(SortOption.amountDesc);
        final oldEpoch = provider.userEpoch;

        provider.setUser(2);
        expect(provider.userEpoch, oldEpoch + 1);
        expect(provider.searchQuery, isEmpty);
        expect(provider.typeFilter, isNull);
        expect(provider.sort, SortOption.newest);
        await _flush();
        var staleNotifications = 0;
        provider.addListener(() => staleNotifications++);

        if (failOldRead) {
          pending.completeError(const AppException('Old-user failure'));
        } else {
          pending.complete([_row(1, 1)]);
        }
        await _flush();

        expect(provider.all.single.userId, 2);
        expect(provider.errorMessage, isNull);
        expect(provider.isLoading, isFalse);
        expect(repository.totalOwners, [2]);
        expect(staleNotifications, 0);
      },
    );
  }

  test('committed insert stays successful when its refresh fails', () async {
    provider.setUser(1);
    await _flush();
    repository.failReadsAfterWrite = true;

    final result = await provider.add(_row(null, 999));

    expect(result.ok, isTrue);
    expect(result.message, contains('Đã lưu giao dịch'));
    expect(provider.errorMessage, result.message);
    expect(repository.insertCalls, 1);
    expect(repository.inserted.single.userId, 1);
    expect(repository.rows[1], hasLength(1));
    expect(provider.isSaving, isFalse);
    expect(provider.lastRefreshSucceeded, isFalse);
    provider.clearError();
    expect(provider.errorMessage, isNull);
    expect(provider.lastRefreshSucceeded, isFalse);

    repository.failReads = false;
    expect(await provider.refresh(), isTrue);
    expect(repository.insertCalls, 1);
    expect(provider.all, hasLength(1));
    expect(provider.errorMessage, isNull);
    expect(provider.lastRefreshSucceeded, isTrue);
  });

  test(
    'pending write belongs to captured user and retains committed outcome',
    () async {
      provider.setUser(1);
      await _flush();
      final write = Completer<void>();
      repository.writeGate = write;
      final saving = provider.add(_row(null, 999));
      await _flush();
      expect(repository.insertCalls, 1);

      provider.setUser(2);
      await _flush();
      var staleNotifications = 0;
      provider.addListener(() => staleNotifications++);
      write.complete();
      final result = await saving;

      expect(result.ok, isTrue);
      expect(result.message, isNull);
      expect(repository.inserted.single.userId, 1);
      expect(provider.userId, 2);
      expect(provider.all, isEmpty);
      expect(provider.isSaving, isFalse);
      expect(provider.errorMessage, isNull);
      expect(staleNotifications, 0);
    },
  );

  test(
    'provider rejects a second mutation while one insert is pending',
    () async {
      provider.setUser(1);
      await _flush();
      final write = Completer<void>();
      repository.writeGate = write;
      final first = provider.add(_row(null, 1));
      final second = await provider.add(_row(null, 1));

      expect(second.ok, isFalse);
      expect(repository.insertCalls, 1);
      write.complete();
      expect((await first).ok, isTrue);
      expect(repository.rows[1], hasLength(1));
    },
  );

  test('committed delete removes local row despite a failed refresh', () async {
    repository.rows[1] = [_row(1, 1), _row(2, 1)];
    provider.setUser(1);
    await _flush();
    repository.failReadsAfterWrite = true;

    expect(await provider.delete(1), isTrue);

    expect(repository.deletedOwners, [1]);
    expect(provider.byId(1), isNull);
    expect(provider.byId(2), isNotNull);
    expect(provider.errorMessage, contains('Đã xóa giao dịch'));
    // Retain the last SQL totals rather than recomputing them from local rows.
    expect(provider.totals.balance, 5000);
  });

  test(
    'search, type and category combine and sorting resets with the user',
    () async {
      repository.rows[1] = [
        _row(
          1,
          1,
        ).copyWith(amount: 300, date: '2026-10-01', category: 'Ăn uống'),
        _row(
          2,
          1,
        ).copyWith(amount: 100, date: '2026-10-02', category: 'Đi lại'),
        _row(
          3,
          1,
        ).copyWith(amount: 200, date: '2026-10-03', category: 'Ăn uống'),
      ];
      provider.setUser(1);
      await _flush();

      expect(provider.visible.map((row) => row.id), [3, 2, 1]);
      provider.setSort(SortOption.oldest);
      expect(provider.visible.map((row) => row.id), [1, 2, 3]);
      provider.setSort(SortOption.amountDesc);
      expect(provider.visible.map((row) => row.id), [1, 3, 2]);
      provider.setSort(SortOption.amountAsc);
      expect(provider.visible.map((row) => row.id), [2, 3, 1]);

      provider.setSearch('a\u0306n uo\u0302\u0301ng');
      provider.setTypeFilter(TxType.expense);
      provider.setCategoryFilter('Ăn uống');
      expect(provider.visible.map((row) => row.id), [3, 1]);
      provider.setTypeFilter(TxType.income);
      expect(provider.categoryFilter, isNull);
      expect(provider.visible, isEmpty);
      provider.clearFilters();
      expect(provider.hasActiveFilters, isFalse);
      expect(provider.visible, hasLength(3));
    },
  );
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

FinanceTransaction _row(int? id, int userId) => FinanceTransaction(
  id: id,
  userId: userId,
  type: TxType.expense,
  amount: 500,
  category: 'Ăn uống',
  date: '2026-10-28',
  createdAt: '2026-10-28T10:00:00',
);

class _BudgetRepository extends FakeBudgets {}

class _TransactionRepository extends Fake implements TransactionRepository {
  final rows = <int, List<FinanceTransaction>>{};
  final totalOwners = <int>[];
  final deletedOwners = <int>[];
  final inserted = <FinanceTransaction>[];
  Future<List<FinanceTransaction>> Function(int)? read;
  Completer<void>? writeGate;
  bool failReads = false;
  bool failReadsAfterWrite = false;
  int insertCalls = 0;

  @override
  Future<List<FinanceTransaction>> getAll(int userId) async {
    if (failReads) throw const AppException('Lỗi cơ sở dữ liệu.');
    if (read != null) return read!(userId);
    return List.of(rows[userId] ?? []);
  }

  @override
  Future<SummaryTotals> getTotals(
    int userId, {
    String? fromDate,
    String? toExclusive,
  }) async {
    if (fromDate == null) totalOwners.add(userId);
    return const SummaryTotals(income: 9000, expense: 4000);
  }

  @override
  Future<List<CategoryTotal>> getExpenseByCategory(
    int userId,
    String fromDate,
    String toExclusive,
  ) async => const [];

  @override
  Future<int> insert(FinanceTransaction transaction) async {
    insertCalls++;
    inserted.add(transaction);
    if (writeGate != null) await writeGate!.future;
    final id = insertCalls;
    rows
        .putIfAbsent(transaction.userId, () => [])
        .add(transaction.copyWith(id: id));
    failReads = failReadsAfterWrite;
    return id;
  }

  @override
  Future<int> delete(int userId, int id) async {
    deletedOwners.add(userId);
    rows[userId]?.removeWhere((row) => row.id == id);
    failReads = failReadsAfterWrite;
    return 1;
  }
}
