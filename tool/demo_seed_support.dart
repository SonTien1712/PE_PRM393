import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pe_prm393_de190630/core/password_hasher.dart';
import 'package:pe_prm393_de190630/core/validators.dart';

import 'demo_dataset.dart';

Future<void> validateDemoDatabase(Database database) async {
  if (await database.getVersion() != 1) {
    throw StateError('Chỉ hỗ trợ schema v1 của Sổ Thu Chi.');
  }
  const expected = {
    'users': {'id', 'username', 'display_name', 'password_hash', 'salt'},
    'transactions': {
      'id',
      'user_id',
      'type',
      'amount',
      'category',
      'date',
      'note',
      'created_at',
    },
    'budgets': {'id', 'user_id', 'month', 'limit_amount'},
  };
  for (final entry in expected.entries) {
    final columns = await database.rawQuery('PRAGMA table_info(${entry.key})');
    if (!columns.map((row) => row['name']).toSet().containsAll(entry.value)) {
      throw StateError(
        'File SQLite không đúng cấu trúc ứng dụng: ${entry.key}.',
      );
    }
  }
  if ((await database.rawQuery('PRAGMA quick_check')).single.values.single !=
          'ok' ||
      (await database.rawQuery('PRAGMA foreign_key_check')).isNotEmpty) {
    throw StateError('SQLite có lỗi toàn vẹn; dừng nạp dữ liệu.');
  }
}

/// SQLite creates a consistent snapshot, including committed WAL contents.
Future<String> backupDemoDatabase(
  Database database,
  Directory directory,
) async {
  await directory.create(recursive: true);
  final file = File(
    path.join(
      directory.path,
      'before_demo_${DateTime.now().microsecondsSinceEpoch}.sqlite',
    ),
  );
  if (await file.exists()) throw StateError('File backup đã tồn tại.');
  await database.execute('VACUUM INTO ?', [file.absolute.path]);
  return file.absolute.path;
}

/// Only missing reserved accounts are inserted. Existing accounts are untouched.
/// A username collision with a different password aborts the whole transaction.
Future<List<Map<String, Object?>>> seedDemoData(
  Database database,
  DateTime asOf,
) async {
  await validateDemoDatabase(database);
  final accounts = buildDemoDataset(asOf);
  for (final account in accounts) {
    final userError =
        validateUsername(account.username) ??
        validatePassword(demoPassword) ??
        validateDisplayName(account.displayName);
    if (userError != null) throw StateError(userError);
    for (final row in account.transactions) {
      final error =
          validateAmount(row.amount.toString()) ??
          validateCategory(row.category, row.type) ??
          validateDate(parseStorageDate(row.date), today: asOf) ??
          validateNote(row.note);
      if (error != null) throw StateError(error);
    }
    for (final budget in account.budgets) {
      final error = validateBudgetLimit(budget.limitAmount.toString());
      if (error != null) throw StateError(error);
    }
  }
  return database.transaction((transaction) async {
    final results = <Map<String, Object?>>[];
    for (final account in accounts) {
      final existing = await transaction.query(
        'users',
        where: 'username = ?',
        whereArgs: [account.username],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        final user = existing.single;
        if (!PasswordHasher.verify(
          demoPassword,
          user['salt'] as String,
          user['password_hash'] as String,
        )) {
          throw StateError(
            'Username ${account.username} đã tồn tại với mật khẩu khác; không ghi đè.',
          );
        }
        results.add({
          'username': account.username,
          'userId': user['id'],
          'status': 'kept_existing',
        });
        continue;
      }
      final salt = PasswordHasher.generateSalt();
      final id = await transaction.insert('users', {
        'username': account.username,
        'display_name': account.displayName,
        'salt': salt,
        'password_hash': PasswordHasher.hash(demoPassword, salt),
      });
      for (final row in account.transactions) {
        await transaction.insert(
          'transactions',
          row.copyWith(userId: id).toMap(),
        );
      }
      for (final budget in account.budgets) {
        await transaction.insert('budgets', {...budget.toMap(), 'user_id': id});
      }
      results.add({
        'username': account.username,
        'userId': id,
        'status': 'created',
      });
    }
    return results;
  });
}

Future<List<Map<String, Object?>>> demoDatabaseSummary(
  Database database,
) async {
  final result = <Map<String, Object?>>[];
  for (final username in demoUsernames) {
    final users = await database.query(
      'users',
      columns: ['id', 'username', 'display_name'],
      where: 'username = ?',
      whereArgs: [username],
    );
    if (users.isEmpty) continue;
    final user = users.single;
    final totals = (await database.rawQuery(
      '''
      SELECT COUNT(*) AS count,
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS expense
      FROM transactions WHERE user_id = ?
    ''',
      [user['id']],
    )).single;
    final months = await database.rawQuery(
      '''
      SELECT b.month, b.limit_amount,
        COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0) AS income,
        COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0) AS expense
      FROM budgets b LEFT JOIN transactions t
        ON t.user_id = b.user_id AND substr(t.date, 1, 7) = b.month
      WHERE b.user_id = ? GROUP BY b.id ORDER BY b.month DESC
    ''',
      [user['id']],
    );
    result.add({
      ...user,
      ...totals,
      'balance': (totals['income'] as int) - (totals['expense'] as int),
      'months': months,
    });
  }
  return result;
}
