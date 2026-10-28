import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pe_prm393_de190630/app.dart';
import 'package:pe_prm393_de190630/core/app_routes.dart';
import 'package:pe_prm393_de190630/data/models/finance_transaction.dart';
import 'package:pe_prm393_de190630/data/session_storage.dart';
import 'package:pe_prm393_de190630/providers/auth_provider.dart';
import 'package:pe_prm393_de190630/providers/transaction_provider.dart';
import 'package:pe_prm393_de190630/screens/home_shell.dart';
import 'package:pe_prm393_de190630/screens/login_screen.dart';
import 'package:pe_prm393_de190630/screens/transaction_detail_screen.dart';
import 'package:pe_prm393_de190630/screens/transaction_form_screen.dart';
import 'package:pe_prm393_de190630/widgets/transaction_tile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

void main() {
  setUpAll(() => initializeDateFormatting('vi_VN'));

  Future<_Harness> start(
    WidgetTester tester, {
    Size size = const Size(360, 640),
    List<FinanceTransaction> rows = const [],
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final auth = AuthProvider(
      FakeUsers(),
      SessionStorage(preferences: preferences),
    );
    addTearDown(auth.dispose);
    final repository = FakeTransactions(rows);
    final transactions = TransactionProvider(repository, FakeBudgets());
    final harness = _Harness(auth, transactions, repository);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
            create: (_) => transactions,
            update: (_, auth, previous) {
              previous!.setUser(auth.currentUser?.id);
              return previous;
            },
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    return harness;
  }

  Future<void> login(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'demo1');
    await tester.enterText(find.byType(TextFormField).at(1), 'Demo@123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);
  }

  Future<void> fillNewForm(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionFormScreen), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), '50000');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ăn uống').last);
    await tester.pumpAndSettle();
    tester.testTextInput.hide();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Lưu giao dịch'),
    );
    await tester.pumpAndSettle();
  }

  for (final size in [const Size(360, 640), const Size(1280, 720)]) {
    testWidgets('login, dashboard, form, and Vietnamese picker at $size', (
      tester,
    ) async {
      await start(
        tester,
        size: size,
        rows: [
          FinanceTransaction(
            id: 1,
            userId: 1,
            type: TxType.income,
            amount: 999999999999,
            category: 'Lương',
            date: '2026-01-01',
            note: 'x' * 200,
            createdAt: '2026-01-01T12:00:00Z',
          ),
        ],
      );
      await login(tester);
      expect(find.text('Tổng thu'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Giao dịch'));
      await tester.pumpAndSettle();
      expect(find.text('Tất cả danh mục'), findsOneWidget);
      await fillNewForm(tester);
      await tester.ensureVisible(find.byType(TextFormField).at(1));
      await tester.tap(find.byType(TextFormField).at(1));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      final picker = tester.element(find.byType(DatePickerDialog));
      expect(Localizations.localeOf(picker).languageCode, 'vi');
      final cancel = MaterialLocalizations.of(picker).cancelButtonLabel;
      await tester.tap(find.text(cancel));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('rapid Save clicks wait for one insert and close once', (
    tester,
  ) async {
    final harness = await start(tester);
    await login(tester);
    await fillNewForm(tester);
    harness.repository.insertGate = Completer<void>();
    final save = find.widgetWithText(FilledButton, 'Lưu giao dịch');
    await tester.tap(save);
    await tester.tap(save);
    await tester.pump();
    expect(harness.repository.insertCalls, 1);
    harness.repository.insertGate!.complete();
    await tester.pumpAndSettle();
    expect(harness.repository.rows, hasLength(1));
    expect(find.byType(TransactionFormScreen), findsNothing);
    expect(find.byType(HomeShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('committed insert with read failure closes with one warning', (
    tester,
  ) async {
    final harness = await start(tester);
    await login(tester);
    await fillNewForm(tester);
    harness.repository.failReadsAfterInsert = true;
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu giao dịch'));
    await tester.pumpAndSettle();
    expect(harness.repository.insertCalls, 1);
    expect(harness.repository.rows, hasLength(1));
    expect(find.byType(TransactionFormScreen), findsNothing);
    expect(find.byType(HomeShell), findsOneWidget);
    expect(
      find.text(
        'Đã lưu giao dịch, nhưng chưa tải lại được dữ liệu. Vui lòng thử tải lại.',
      ),
      findsOneWidget,
    );
    expect(harness.transactions.needsRefresh, isTrue);
    harness.repository.failReads = false;
    await tester.tap(find.text('Thử tải lại'));
    await tester.pumpAndSettle();
    expect(harness.transactions.needsRefresh, isFalse);
    expect(harness.repository.insertCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'logout above stacked protected routes redirects once and clears stack',
    (tester) async {
      final harness = await start(tester);
      await login(tester);
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      unawaited(
        navigator.pushNamed(AppRoutes.transactionDetail, arguments: 999),
      );
      // The form is current when logout occurs, even with protected ancestors.
      unawaited(navigator.pushNamed(AppRoutes.transactionNew));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionFormScreen), findsOneWidget);
      await harness.auth.logout();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeShell), findsNothing);
      expect(find.byType(TransactionFormScreen), findsNothing);
      expect(find.byType(TransactionDetailScreen), findsNothing);
      expect(navigator.canPop(), isFalse);
      expect(harness.transactions.all, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('direct protected route while signed out never builds a form', (
    tester,
  ) async {
    await start(tester);
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    unawaited(navigator.pushNamed(AppRoutes.transactionNew));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TransactionFormScreen), findsNothing);
    expect(navigator.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'edit updates live detail and totals; delete cancel/confirm closes once',
    (tester) async {
      final harness = await start(tester);
      await login(tester);
      await fillNewForm(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Lưu giao dịch'));
      await tester.pumpAndSettle();
      expect(harness.transactions.totals.expense, 50000);
      await tester.pump(const Duration(seconds: 5));
      await tester.ensureVisible(find.byType(TransactionTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TransactionTile).first);
      await tester.pumpAndSettle();
      expect(find.byType(TransactionDetailScreen), findsOneWidget);
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Sửa giao dịch'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Sửa giao dịch'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '200000');
      await tester.tap(find.text('Thu').hitTestable());
      await tester.pumpAndSettle();
      expect(harness.repository.rows.single.category, 'Ăn uống');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thưởng').last);
      await tester.pumpAndSettle();
      tester.testTextInput.hide();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Lưu giao dịch'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Lưu giao dịch'));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionFormScreen), findsNothing);
      expect(find.byType(TransactionDetailScreen), findsOneWidget);
      expect(find.text('Khoản thu'), findsOneWidget);
      expect(harness.transactions.totals.income, 200000);
      expect(harness.transactions.totals.expense, 0);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      final delete = find.widgetWithText(OutlinedButton, 'Xóa giao dịch');
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      // The disabled delete button animates while the confirmation is pending.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
      await tester.pumpAndSettle();
      expect(harness.repository.rows, hasLength(1));
      expect(find.byType(TransactionDetailScreen), findsOneWidget);
      await tester.tap(delete);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
      await tester.pumpAndSettle();
      expect(harness.repository.rows, isEmpty);
      expect(harness.transactions.totals.balance, 0);
      expect(find.byType(TransactionDetailScreen), findsNothing);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _Harness {
  const _Harness(this.auth, this.transactions, this.repository);
  final AuthProvider auth;
  final TransactionProvider transactions;
  final FakeTransactions repository;
}
