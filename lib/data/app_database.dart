import 'dart:io' show Directory;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../core/constants.dart';
import '../core/password_hasher.dart';
import '../core/platform_utils.dart';

class AppDatabase {
  AppDatabase._(this.db);

  final Database db;
  static const _dbName = 'finance_tracker.db';
  static const _dbVersion = 1;

  static Future<String> defaultPath(DatabaseFactory factory) async {
    if (isDesktop) {
      final directory = await getApplicationSupportDirectory();
      await Directory(directory.path).create(recursive: true);
      return p.join(directory.path, _dbName);
    }
    return p.join(await factory.getDatabasesPath(), _dbName);
  }

  static Future<AppDatabase> open({
    String? path,
    DatabaseFactory? factory,
  }) async {
    final selectedFactory = factory ?? databaseFactory;
    final databasePath = path ?? await defaultPath(selectedFactory);
    final database = await selectedFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    return AppDatabase._(database);
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        display_name TEXT NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
        amount INTEGER NOT NULL CHECK (amount > 0 AND amount <= $maxAmount),
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    batch.execute(
      'CREATE INDEX idx_tx_user_date ON transactions(user_id, date DESC)',
    );
    batch.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        month TEXT NOT NULL,
        limit_amount INTEGER NOT NULL
          CHECK (limit_amount > 0 AND limit_amount <= $maxAmount),
        UNIQUE (user_id, month),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    for (final account in seedAccounts) {
      final salt = PasswordHasher.generateSalt();
      batch.insert('users', {
        'username': account.username,
        'password_hash': PasswordHasher.hash(account.password, salt),
        'salt': salt,
        'display_name': account.displayName,
      });
    }
    await batch.commit(noResult: true);
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Version 1 has no migrations. Add incremental steps when the schema grows.
  }

  Future<void> close() => db.close();
}
