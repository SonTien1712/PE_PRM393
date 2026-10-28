import 'dart:io' show Directory, File;

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pe_prm393_de190630/data/app_database.dart';
import 'package:pe_prm393_de190630/data/models/finance_transaction.dart';
import 'package:pe_prm393_de190630/data/repositories/transaction_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);
  test(
    'a disk database retains rows and seeds after close and reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'finance_tracker_test_',
      );
      final path = p.join(directory.path, 'finance_tracker.db');
      AppDatabase? database;
      try {
        database = await AppDatabase.open(
          path: path,
          factory: databaseFactoryFfi,
        );
        final id = await TransactionRepository(database).insert(
          const FinanceTransaction(
            userId: 1,
            type: TxType.income,
            amount: 10000000,
            category: 'Lương',
            date: '2026-01-01',
            createdAt: '2026-01-01T12:00:00Z',
          ),
        );
        await database.close();
        database = null;
        database = await AppDatabase.open(
          path: path,
          factory: databaseFactoryFfi,
        );
        final repository = TransactionRepository(database);
        expect((await repository.getById(1, id))?.amount, 10000000);
        expect(await repository.getAll(2), isEmpty);
        expect((await repository.getTotals(1)).balance, 10000000);
        final seeds = await database.db.query('users', orderBy: 'id ASC');
        expect(seeds.map((row) => row['username']), ['demo1', 'demo2']);
      } finally {
        await database?.close();
        final file = File(path);
        if (await file.exists()) await file.delete();
        await directory.delete();
      }
    },
  );
}
