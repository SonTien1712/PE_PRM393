import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pe_prm393_de190630/app.dart';
import 'package:pe_prm393_de190630/data/csv_export_service.dart';
import 'package:pe_prm393_de190630/data/models/finance_transaction.dart';
import 'package:pe_prm393_de190630/providers/auth_provider.dart';
import 'package:pe_prm393_de190630/providers/transaction_provider.dart';

import 'fakes.dart';

class AppHarness {
  AppHarness(this.auth, this.transactions, this.rows, this.budgets);
  final AuthProvider auth;
  final TransactionProvider transactions;
  final FakeTransactions rows;
  final FakeBudgets budgets;
}

Future<AppHarness> pumpTestApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  List<FinanceTransaction> rows = const [],
  FakeBudgets? budgets,
  CsvExportService? exporter,
  FakeTransactions? transactionRepository,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final auth = AuthProvider(FakeUsers(), FakeSession(null));
  final repository = transactionRepository ?? FakeTransactions(rows);
  final budgetRepository = budgets ?? FakeBudgets();
  final transactions = TransactionProvider(
    repository,
    budgetRepository,
    now: () => DateTime(2026, 10, 28),
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<CsvExportService>.value(value: exporter ?? CsvExportService()),
        ChangeNotifierProvider<AuthProvider>(create: (_) => auth),
        ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
          create: (_) => transactions,
          update: (_, auth, previous) {
            previous!.setUser(auth.currentUser?.id);
            return previous;
          },
        ),
      ],
      child: App(now: () => DateTime(2026, 10, 28)),
    ),
  );
  await tester.pumpAndSettle();
  return AppHarness(auth, transactions, repository, budgetRepository);
}

Future<void> loginDemo(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'demo1');
  await tester.enterText(find.byType(TextFormField).at(1), 'Demo@123');
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}
