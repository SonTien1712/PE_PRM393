import 'package:flutter_test/flutter_test.dart';
import 'package:pe_prm393_de190630/core/app_exception.dart';
import 'package:pe_prm393_de190630/core/constants.dart';
import 'package:pe_prm393_de190630/data/app_database.dart';
import 'package:pe_prm393_de190630/data/models/finance_transaction.dart';
import 'package:pe_prm393_de190630/data/repositories/transaction_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);
  test(
    'real SQLite write failure is translated and does not insert a row',
    () async {
      final database = await AppDatabase.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final repository = TransactionRepository(database);
      await database.db.execute('PRAGMA query_only = ON');
      try {
        await expectLater(
          repository.insert(
            const FinanceTransaction(
              userId: 1,
              type: TxType.expense,
              amount: 50000,
              category: 'Ăn uống',
              date: '2026-01-01',
              createdAt: '2026-01-01T12:00:00Z',
            ),
          ),
          throwsA(
            isA<AppException>().having(
              (error) => error.message,
              'message',
              databaseErrorMessage,
            ),
          ),
        );
        expect(await repository.getAll(1), isEmpty);
      } finally {
        await database.db.execute('PRAGMA query_only = OFF');
        await database.close();
      }
    },
  );
}
