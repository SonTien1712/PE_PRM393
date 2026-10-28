import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../core/categories.dart';
import '../core/constants.dart';
import '../core/text_utils.dart';
import '../data/models/finance_transaction.dart';
import '../data/models/save_result.dart';
import '../data/models/summary_totals.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/transaction_repository.dart';

enum SortOption { newest, oldest, amountDesc, amountAsc }

class TransactionProvider extends ChangeNotifier {
  TransactionProvider(this._transactions, BudgetRepository budgetRepository);

  final TransactionRepository _transactions;
  static const _emptyTotals = SummaryTotals(income: 0, expense: 0);
  static const _saveWarning =
      'Đã lưu giao dịch, nhưng chưa tải lại được dữ liệu. Vui lòng thử tải lại.';
  static const _deleteWarning =
      'Đã xóa giao dịch, nhưng chưa tải lại được dữ liệu. Vui lòng thử tải lại.';

  List<FinanceTransaction> _all = const [];
  SummaryTotals _totals = _emptyTotals;
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
  bool get needsRefresh => _needsRefresh;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  TxType? get typeFilter => _typeFilter;
  String? get categoryFilter => _categoryFilter;
  SortOption get sort => _sort;

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
    _isLoading = true;
    _lastRefreshSucceeded = false;
    _errorMessage = null;
    notifyListeners();
    try {
      final rows = await _transactions.getAll(userId);
      if (!_isCurrentRead(epoch, version)) return false;
      final totals = await _transactions.getTotals(userId);
      if (!_isCurrentRead(epoch, version)) return false;
      // Publish the rows and SQL totals together, retaining the prior snapshot
      // if either query fails. An older refresh cannot replace a newer one.
      _all = List.unmodifiable(rows);
      _totals = totals;
      _hasLoaded = true;
      _lastRefreshSucceeded = true;
      _needsRefresh = false;
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
      return const SaveResult(ok: true);
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
