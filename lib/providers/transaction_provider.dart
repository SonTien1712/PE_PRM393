import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../core/categories.dart';
import '../core/budget_alert_calculator.dart';
import '../core/constants.dart';
import '../core/csv_export.dart';
import '../core/month_utils.dart';
import '../core/text_utils.dart';
import '../data/models/category_total.dart';
import '../data/models/budget.dart';
import '../data/models/budget_alert.dart';
import '../data/models/finance_transaction.dart';
import '../data/models/save_result.dart';
import '../data/models/summary_totals.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/transaction_repository.dart';

enum SortOption { newest, oldest, amountDesc, amountAsc }

class TransactionProvider extends ChangeNotifier {
  TransactionProvider(
    this._transactions,
    this._budgets, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _selectedMonth = _currentMonth;
  }

  final TransactionRepository _transactions;
  final BudgetRepository _budgets;
  final DateTime Function() _now;
  static const _emptyTotals = SummaryTotals(income: 0, expense: 0);
  static const _saveWarning =
      'Đã lưu giao dịch, nhưng chưa tải lại được dữ liệu. Vui lòng thử tải lại.';
  static const _deleteWarning =
      'Đã xóa giao dịch, nhưng chưa tải lại được dữ liệu. Vui lòng thử tải lại.';

  List<FinanceTransaction> _all = const [];
  SummaryTotals _totals = _emptyTotals;
  late DateTime _selectedMonth;
  SummaryTotals _monthTotals = _emptyTotals;
  List<CategoryTotal> _monthBreakdown = const [];
  Budget? _monthBudget;
  String? _monthDataKey;
  int _monthReadVersion = 0;
  bool _isMonthLoading = false;
  bool _monthNeedsRefresh = false;
  int? _userId;
  int _epoch = 0;
  int _readVersion = 0;
  bool _disposed = false;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasLoaded = false;
  bool _lastRefreshSucceeded = false;
  bool _needsRefresh = false;
  String? _errorMessage;
  String _searchQuery = '';
  TxType? _typeFilter;
  String? _categoryFilter;
  SortOption _sort = SortOption.newest;

  List<FinanceTransaction> get all => _all;
  List<FinanceTransaction> get transactions => _all;
  SummaryTotals get totals => _totals;
  int? get userId => _userId;
  int get userEpoch => _epoch;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get mutationBusy => _isSaving;
  bool get hasLoaded => _hasLoaded;
  bool get lastRefreshSucceeded => _lastRefreshSucceeded;
  bool get needsRefresh => _needsRefresh || _monthNeedsRefresh;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  TxType? get typeFilter => _typeFilter;
  String? get categoryFilter => _categoryFilter;
  SortOption get sort => _sort;
  DateTime get selectedMonth => _selectedMonth;
  String get selectedMonthKey => monthKey(_selectedMonth);
  SummaryTotals get monthTotals => _monthTotals;
  List<CategoryTotal> get monthBreakdown => _monthBreakdown;
  bool get hasMonthData => _monthDataKey == selectedMonthKey;
  bool get isMonthLoading => _isMonthLoading;
  Budget? get monthBudget => hasMonthData ? _monthBudget : null;
  bool get canGoNextMonth => _selectedMonth.isBefore(_currentMonth);
  DateTime get _currentMonth => DateTime(_now().year, _now().month);

  bool _isCurrent(int epoch) => !_disposed && epoch == _epoch;
  bool _isCurrentRead(int epoch, int version) =>
      _isCurrent(epoch) && version == _readVersion;

  void setUser(int? userId) {
    if (_disposed || userId == _userId) return;
    final epoch = ++_epoch;
    _userId = userId;
    _readVersion++;
    _all = const [];
    _totals = _emptyTotals;
    _selectedMonth = _currentMonth;
    _monthTotals = _emptyTotals;
    _monthBreakdown = const [];
    _monthBudget = null;
    _monthDataKey = null;
    _monthReadVersion++;
    _isMonthLoading = false;
    _monthNeedsRefresh = false;
    _isLoading = false;
    _isSaving = false;
    _hasLoaded = false;
    _lastRefreshSucceeded = false;
    _needsRefresh = false;
    _errorMessage = null;
    _searchQuery = '';
    _typeFilter = null;
    _categoryFilter = null;
    _sort = SortOption.newest;
    // ProxyProvider calls this during build: no synchronous notifications.
    scheduleMicrotask(() {
      if (!_isCurrent(epoch)) return;
      notifyListeners();
      if (userId != null) unawaited(refresh());
    });
  }

  void clearError() {
    if (_disposed || _errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> refresh() async {
    final epoch = _epoch;
    final userId = _userId;
    if (userId == null || _disposed) return false;
    final version = ++_readVersion;
    final monthVersion = ++_monthReadVersion;
    final month = _selectedMonth;
    _isLoading = true;
    _isMonthLoading = true;
    _lastRefreshSucceeded = false;
    _errorMessage = null;
    notifyListeners();
    try {
      final rows = await _transactions.getAll(userId);
      if (!_isCurrentRead(epoch, version)) return false;
      final totals = await _transactions.getTotals(userId);
      if (!_isCurrentRead(epoch, version)) return false;
      final monthData = await _readMonth(userId, month);
      if (!_isCurrentRead(epoch, version) ||
          monthVersion != _monthReadVersion) {
        return false;
      }
      // Publish the rows and SQL totals together, retaining the prior snapshot
      // if either query fails. An older refresh cannot replace a newer one.
      _all = List.unmodifiable(rows);
      _totals = totals;
      _publishMonth(month, monthData);
      _hasLoaded = true;
      _lastRefreshSucceeded = true;
      _needsRefresh = false;
      _monthNeedsRefresh = false;
      _errorMessage = null;
      return true;
    } catch (error, stack) {
      debugPrint('Transaction refresh failed: $error\n$stack');
      if (_isCurrentRead(epoch, version)) {
        _needsRefresh = true;
        _errorMessage = _messageFor(error);
      }
      return false;
    } finally {
      if (_isCurrentRead(epoch, version)) {
        _isLoading = false;
        if (monthVersion == _monthReadVersion) _isMonthLoading = false;
        notifyListeners();
      }
    }
  }

  Future<(SummaryTotals, List<CategoryTotal>, Budget?)> _readMonth(
    int userId,
    DateTime month,
  ) async {
    final (from, to) = monthRange(month);
    final totals = await _transactions.getTotals(
      userId,
      fromDate: from,
      toExclusive: to,
    );
    final breakdown = await _transactions.getExpenseByCategory(
      userId,
      from,
      to,
    );
    final budget = await _budgets.getForMonth(userId, monthKey(month));
    return (totals, breakdown, budget);
  }

  void _publishMonth(
    DateTime month,
    (SummaryTotals, List<CategoryTotal>, Budget?) data,
  ) {
    _monthTotals = data.$1;
    _monthBreakdown = List.unmodifiable(data.$2);
    _monthBudget = data.$3;
    _monthDataKey = monthKey(month);
  }

  Future<void> changeMonth(int deltaMonths) async {
    if (_disposed || _userId == null || _isSaving || deltaMonths == 0) return;
    final next = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + deltaMonths,
    );
    if (next.isAfter(_currentMonth) || next.isBefore(DateTime(2000))) return;
    _selectedMonth = next;
    // A new selection must not be labelled with the previous month's snapshot.
    if (!_hasLoaded || _isLoading) {
      await refresh();
      return;
    }
    final epoch = _epoch;
    final userId = _userId!;
    final version = ++_monthReadVersion;
    _isMonthLoading = true;
    _errorMessage = null;
    notifyListeners();
    bool current() => _isCurrent(epoch) && version == _monthReadVersion;
    try {
      final data = await _readMonth(userId, next);
      if (!current()) return;
      _publishMonth(next, data);
      _monthNeedsRefresh = false;
    } catch (error, stack) {
      debugPrint('Month refresh failed: $error\n$stack');
      if (current()) {
        _monthNeedsRefresh = true;
        _errorMessage = _messageFor(error);
      }
    } finally {
      if (current()) {
        _isMonthLoading = false;
        notifyListeners();
      }
    }
  }

  Future<SaveResult> add(FinanceTransaction transaction) =>
      _save(transaction, updating: false);

  Future<SaveResult> update(FinanceTransaction transaction) =>
      _save(transaction, updating: true);

  Future<SaveResult> _save(
    FinanceTransaction transaction, {
    required bool updating,
  }) async {
    final epoch = _epoch;
    final userId = _userId;
    if (_disposed || userId == null) {
      return const SaveResult(
        ok: false,
        message: 'Vui lòng đăng nhập để tiếp tục.',
      );
    }
    if (_isSaving) {
      return const SaveResult(ok: false, message: 'Đang lưu. Vui lòng chờ.');
    }
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    var committed = false;
    try {
      // Ownership is always taken from this captured authenticated session.
      final owned = transaction.copyWith(userId: userId);
      final alert = await _prepareBudgetAlert(owned, updating: updating);
      if (!_isCurrent(epoch)) return const SaveResult(ok: false);
      if (updating) {
        await _transactions.update(owned);
      } else {
        await _transactions.insert(owned);
      }
      committed = true;
      if (!_isCurrent(epoch)) return const SaveResult(ok: true);
      final loaded = await refresh();
      if (!_isCurrent(epoch)) return const SaveResult(ok: true);
      if (!loaded) {
        _errorMessage = _saveWarning;
        return const SaveResult(ok: true, message: _saveWarning);
      }
      return SaveResult(ok: true, alert: alert);
    } catch (error, stack) {
      debugPrint('Transaction save failed: $error\n$stack');
      if (!_isCurrent(epoch)) return SaveResult(ok: committed);
      if (committed) {
        _needsRefresh = true;
        _errorMessage = _saveWarning;
        return const SaveResult(ok: true, message: _saveWarning);
      }
      final message = _messageFor(error);
      if (error is AppException &&
          error.message == 'Không tìm thấy giao dịch') {
        await refresh();
        if (!_isCurrent(epoch)) return const SaveResult(ok: false);
      }
      // The initiating form owns write-error messages through SaveResult.
      return SaveResult(ok: false, message: message);
    } finally {
      if (_isCurrent(epoch)) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<bool> delete(int id) async {
    final epoch = _epoch;
    final userId = _userId;
    if (_disposed || userId == null || _isSaving) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    var committed = false;
    try {
      await _transactions.delete(userId, id);
      committed = true;
      if (!_isCurrent(epoch)) return true;
      final loaded = await refresh();
      if (!_isCurrent(epoch)) return true;
      if (!loaded) {
        _all = List.unmodifiable(_all.where((row) => row.id != id));
        _errorMessage = _deleteWarning;
      }
      return true;
    } catch (error, stack) {
      debugPrint('Transaction delete failed: $error\n$stack');
      if (!_isCurrent(epoch)) return committed;
      if (committed) {
        _all = List.unmodifiable(_all.where((row) => row.id != id));
        _errorMessage = _deleteWarning;
        return true;
      }
      final message = _messageFor(error);
      if (error is AppException &&
          error.message == 'Không tìm thấy giao dịch') {
        await refresh();
        if (!_isCurrent(epoch)) return false;
      }
      _errorMessage = message;
      return false;
    } finally {
      if (_isCurrent(epoch)) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<BudgetAlert?> _prepareBudgetAlert(
    FinanceTransaction transaction, {
    required bool updating,
  }) async {
    if (transaction.type != TxType.expense) return null;
    final epoch = _epoch;
    final month = DateTime.tryParse(transaction.date);
    if (month == null) return null;
    try {
      final budget = await _budgets.getForMonth(
        transaction.userId,
        monthKey(month),
      );
      if (!_isCurrent(epoch) || budget == null) return null;
      final (from, to) = monthRange(month);
      final before = await _transactions.getTotals(
        transaction.userId,
        fromDate: from,
        toExclusive: to,
      );
      if (!_isCurrent(epoch)) return null;
      FinanceTransaction? old;
      if (updating && transaction.id != null) {
        old = await _transactions.getById(transaction.userId, transaction.id!);
        if (!_isCurrent(epoch)) return null;
      }
      final oldAmount =
          old != null &&
              old.type == TxType.expense &&
              old.date.substring(0, 7) == monthKey(month)
          ? old.amount
          : 0;
      return calculateBudgetAlert(
        beforeSpent: before.expense,
        afterSpent: before.expense - oldAmount + transaction.amount,
        limit: budget.limitAmount,
      );
    } catch (error, stack) {
      // Optional alert reads cannot prevent a valid transaction write.
      debugPrint('Budget alert unavailable: $error\n$stack');
      return null;
    }
  }

  Future<void> saveBudget(int limit) => _writeBudget(limit);
  Future<void> removeBudget() => _writeBudget(null);

  Future<void> _writeBudget(int? limit) async {
    final epoch = _epoch;
    final userId = _userId;
    final month = selectedMonthKey;
    if (_disposed || userId == null) {
      throw const AppException('Vui lòng đăng nhập để tiếp tục.');
    }
    if (_isSaving) throw const AppException('Đang lưu. Vui lòng chờ.');
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    var committed = false;
    final warning = limit == null
        ? 'Đã xóa ngân sách, nhưng chưa tải lại được dữ liệu. Vui lòng thử tải lại.'
        : 'Đã lưu ngân sách, nhưng chưa tải lại được dữ liệu. Vui lòng thử tải lại.';
    try {
      final budget = limit == null
          ? null
          : Budget(
              id: monthBudget?.id,
              userId: userId,
              month: month,
              limitAmount: limit,
            );
      if (budget == null) {
        await _budgets.delete(userId, month);
      } else {
        await _budgets.upsert(budget);
      }
      committed = true;
      if (!_isCurrent(epoch)) return;
      if (selectedMonthKey == month) _monthBudget = budget;
      final loaded = await refresh();
      if (!_isCurrent(epoch)) return;
      if (!loaded) _errorMessage = warning;
    } catch (error, stack) {
      debugPrint('Budget write failed: $error\n$stack');
      if (!_isCurrent(epoch)) return;
      if (committed) {
        _needsRefresh = true;
        _errorMessage = warning;
      } else {
        throw AppException(_messageFor(error));
      }
    } finally {
      if (_isCurrent(epoch)) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<String> buildCsv() async {
    final epoch = _epoch;
    final userId = _userId;
    if (_disposed || userId == null) {
      throw const AppException('Vui lòng đăng nhập để tiếp tục.');
    }
    try {
      final rows = await _transactions.getAll(userId);
      if (!_isCurrent(epoch)) {
        throw const AppException('Phiên đăng nhập đã thay đổi.');
      }
      if (rows.isEmpty) throw const AppException('Chưa có dữ liệu để xuất');
      return buildTransactionsCsv(rows);
    } catch (error) {
      if (error is AppException) rethrow;
      debugPrint('CSV read failed: $error');
      throw const AppException('Không thể xuất file. Vui lòng thử lại.');
    }
  }

  FinanceTransaction? byId(int id) {
    for (final transaction in _all) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  List<String> get categoryOptions => _typeFilter == null
      ? {...incomeCategories, ...expenseCategories}.toList()
      : categoriesFor(_typeFilter!);

  bool get hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _typeFilter != null ||
      _categoryFilter != null ||
      _sort != SortOption.newest;

  List<FinanceTransaction> get visible {
    final query = normalizeVi(_searchQuery);
    final rows = _all.where((row) {
      if (_typeFilter != null && row.type != _typeFilter) return false;
      if (_categoryFilter != null && row.category != _categoryFilter) {
        return false;
      }
      return query.isEmpty ||
          normalizeVi(row.category).contains(query) ||
          normalizeVi(row.note ?? '').contains(query);
    }).toList();
    rows.sort((left, right) {
      final newest = right.date.compareTo(left.date);
      final byDate = newest != 0
          ? newest
          : (right.id ?? 0).compareTo(left.id ?? 0);
      return switch (_sort) {
        SortOption.newest => byDate,
        SortOption.oldest => -byDate,
        SortOption.amountDesc =>
          left.amount == right.amount
              ? byDate
              : right.amount.compareTo(left.amount),
        SortOption.amountAsc =>
          left.amount == right.amount
              ? byDate
              : left.amount.compareTo(right.amount),
      };
    });
    return rows;
  }

  void setSearch(String query) {
    if (_disposed || query == _searchQuery) return;
    _searchQuery = query;
    notifyListeners();
  }

  void setTypeFilter(TxType? type) {
    if (_disposed || type == _typeFilter) return;
    _typeFilter = type;
    if (!categoryOptions.contains(_categoryFilter)) _categoryFilter = null;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    if (_disposed || category == _categoryFilter) return;
    _categoryFilter = categoryOptions.contains(category) ? category : null;
    notifyListeners();
  }

  void setSort(SortOption sort) {
    if (_disposed || sort == _sort) return;
    _sort = sort;
    notifyListeners();
  }

  void clearFilters() {
    if (_disposed || !hasActiveFilters) return;
    _searchQuery = '';
    _typeFilter = null;
    _categoryFilter = null;
    _sort = SortOption.newest;
    notifyListeners();
  }

  String _messageFor(Object error) =>
      error is AppException ? error.message : databaseErrorMessage;

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
