import 'package:sqflite/sqflite.dart';

import '../../core/app_exception.dart';
import '../../core/password_hasher.dart';
import '../../core/validators.dart';
import '../app_database.dart';
import '../models/app_user.dart';
import 'repository_support.dart';

class UserRepository {
  UserRepository(this._database);

  final AppDatabase _database;

  Future<AppUser?> findById(int id) => runDatabaseOperation(() async {
    final rows = await _database.db.query(
      'users',
      columns: ['id', 'username', 'display_name'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  });

  Future<AppUser?> authenticate(String username, String password) =>
      runDatabaseOperation(() async {
        final rows = await _database.db.query(
          'users',
          where: 'username = ?',
          whereArgs: [username.trim().toLowerCase()],
          limit: 1,
        );
        if (rows.isEmpty) return null;
        final row = rows.first;
        if (!PasswordHasher.verify(
          password,
          row['salt'] as String,
          row['password_hash'] as String,
        )) {
          return null;
        }
        return AppUser.fromMap(row);
      });

  Future<AppUser> register({
    required String username,
    required String password,
    required String displayName,
  }) => runDatabaseOperation(() async {
    final normalizedUsername = username.trim().toLowerCase();
    final error =
        validateUsername(normalizedUsername) ??
        validatePassword(password) ??
        validateDisplayName(displayName);
    if (error != null) throw AppException(error);
    final salt = PasswordHasher.generateSalt();
    try {
      final id = await _database.db.insert('users', {
        'username': normalizedUsername,
        'password_hash': PasswordHasher.hash(password, salt),
        'salt': salt,
        'display_name': displayName.trim(),
      });
      return AppUser(
        id: id,
        username: normalizedUsername,
        displayName: displayName.trim(),
      );
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const AppException('Tên đăng nhập đã tồn tại');
      }
      rethrow;
    }
  });
}
