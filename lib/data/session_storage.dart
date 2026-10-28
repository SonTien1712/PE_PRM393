import 'package:shared_preferences/shared_preferences.dart';

class SessionData {
  const SessionData({required this.userId, required this.createdAt});

  final int userId;
  final DateTime createdAt;
}

class SessionStorage {
  SessionStorage({this._preferences, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const _kUserId = 'session_user_id';
  static const _kCreatedAt = 'session_created_at_ms';
  final SharedPreferences? _preferences;
  final DateTime Function() _now;

  Future<SharedPreferences> _getPreferences() async =>
      _preferences ?? await SharedPreferences.getInstance();

  Future<void> save(int userId) async {
    final preferences = await _getPreferences();
    final timestamp = _now().millisecondsSinceEpoch;
    if (!await preferences.setInt(_kUserId, userId)) {
      throw StateError('Không lưu được phiên đăng nhập');
    }
    if (!await preferences.setInt(_kCreatedAt, timestamp)) {
      throw StateError('Không lưu được phiên đăng nhập');
    }
  }

  Future<SessionData?> read() async {
    final preferences = await _getPreferences();
    final userId = preferences.getInt(_kUserId);
    final timestamp = preferences.getInt(_kCreatedAt);
    if (userId == null || timestamp == null) {
      if (userId != null || timestamp != null) await clear();
      return null;
    }
    return SessionData(
      userId: userId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
  }

  Future<void> clear() async {
    final preferences = await _getPreferences();
    final userRemoved = await preferences.remove(_kUserId);
    final timestampRemoved = await preferences.remove(_kCreatedAt);
    if (!userRemoved || !timestampRemoved) {
      throw StateError('Không xóa được phiên đăng nhập');
    }
  }
}
