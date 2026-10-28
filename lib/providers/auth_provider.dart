import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../core/constants.dart';
import '../data/models/app_user.dart';
import '../data/repositories/user_repository.dart';
import '../data/session_storage.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._users, this._session, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final UserRepository _users;
  final SessionStorage _session;
  final DateTime Function() _now;

  AppUser? _currentUser;
  bool _isBusy = false;
  bool _disposed = false;
  int _operation = 0;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  void clearError() {
    if (_disposed || _errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  bool _isCurrent(int operation) => !_disposed && operation == _operation;

  int _begin() {
    _isBusy = true;
    _errorMessage = null;
    final operation = ++_operation;
    notifyListeners();
    return operation;
  }

  void _finish(int operation) {
    if (!_isCurrent(operation)) return;
    _isBusy = false;
    notifyListeners();
  }

  Future<bool> restoreSession() async {
    if (_disposed || _isBusy) return false;
    final operation = _begin();
    try {
      SessionData? session;
      try {
        session = await _session.read();
      } catch (error, stack) {
        debugPrint('Session read failed: $error\n$stack');
        if (_isCurrent(operation)) {
          _errorMessage =
              'Không đọc được phiên đăng nhập. Vui lòng đăng nhập lại.';
        }
        // A read failure must not erase a potentially valid saved session.
        return false;
      }
      if (!_isCurrent(operation)) return false;
      if (session == null) {
        _currentUser = null;
        return false;
      }

      final age = _now().difference(session.createdAt);
      if (age.isNegative || age >= sessionMaxAge) {
        await _session.clear();
        if (_isCurrent(operation)) _currentUser = null;
        return false;
      }

      final user = await _users.findById(session.userId);
      if (!_isCurrent(operation)) return false;
      if (user == null) {
        await _session.clear();
        if (_isCurrent(operation)) _currentUser = null;
        return false;
      }
      _currentUser = user;
      return true;
    } catch (error, stack) {
      debugPrint('Session restoration failed: $error\n$stack');
      if (_isCurrent(operation)) {
        _errorMessage = error is AppException
            ? error.message
            : 'Không thể khôi phục phiên đăng nhập. Vui lòng đăng nhập lại.';
      }
      return false;
    } finally {
      _finish(operation);
    }
  }

  Future<bool> login(String username, String password) async {
    if (_disposed || _isBusy) return false;
    final operation = _begin();
    try {
      final user = await _users.authenticate(username, password);
      if (!_isCurrent(operation)) return false;
      if (user == null) {
        _errorMessage = 'Sai tên đăng nhập hoặc mật khẩu';
        return false;
      }
      await _session.save(user.id);
      if (!_isCurrent(operation)) return false;
      _currentUser = user;
      return true;
    } catch (error, stack) {
      debugPrint('Login failed: $error\n$stack');
      if (_isCurrent(operation)) {
        _errorMessage = error is AppException
            ? error.message
            : 'Không thể đăng nhập. Vui lòng thử lại.';
      }
      return false;
    } finally {
      _finish(operation);
    }
  }

  Future<void> logout() async {
    if (_disposed || _isBusy) return;
    final operation = _begin();
    try {
      await _session.clear();
      if (_isCurrent(operation)) _currentUser = null;
    } catch (error, stack) {
      debugPrint('Logout failed: $error\n$stack');
      if (_isCurrent(operation)) {
        _errorMessage = 'Không thể đăng xuất. Vui lòng thử lại.';
      }
    } finally {
      // RequireAuth observes the new user and owns all logout navigation.
      _finish(operation);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _operation++;
    super.dispose();
  }
}
