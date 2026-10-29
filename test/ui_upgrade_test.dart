import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pe_prm393_de190630/core/app_routes.dart';
import 'package:pe_prm393_de190630/core/app_theme.dart';
import 'package:pe_prm393_de190630/data/models/finance_transaction.dart';
import 'package:pe_prm393_de190630/providers/transaction_provider.dart';
import 'package:pe_prm393_de190630/screens/home_shell.dart';
import 'package:pe_prm393_de190630/screens/transaction_detail_screen.dart';
import 'package:pe_prm393_de190630/widgets/dashboard_skeleton.dart';
import 'package:pe_prm393_de190630/widgets/info_banner.dart';
import 'package:pe_prm393_de190630/widgets/transaction_fields.dart';

import 'helpers/app_harness.dart';
import 'helpers/fakes.dart';
import 'helpers/load_fonts.dart';

FinanceTransaction entry(
  int id,
  int amount, {
  String category = 'Ăn uống',
  String? note,
}) => FinanceTransaction(
  id: id,
  userId: 1,
  type: TxType.expense,
  amount: amount,
  category: category,
  date: '2026-10-28',
  note: note,
  createdAt: '2026-10-28T08:00:00',
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN');
    await loadAppFonts();
  });

  testWidgets(
    'login failure stays inline, preserves username and clears password',
    (tester) async {
      final app = await pumpTestApp(tester);
      await tester.enterText(find.byType(TextFormField).at(0), 'demo1');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byType(InfoBanner), findsOneWidget);
      expect(find.text('Sai tên đăng nhập hoặc mật khẩu'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(0))
            .controller!
            .text,
        'demo1',
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        isEmpty,
      );
      expect(app.auth.currentUser, isNull);
      await tester.enterText(find.byType(TextFormField).at(1), 'Demo@123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('first load shows placeholders without fabricated zero totals', (
    tester,
  ) async {
    final rows = _DelayedRows([entry(1, 500)]);
    final app = await pumpTestApp(tester, transactionRepository: rows);
    await tester.enterText(find.byType(TextFormField).at(0), 'demo1');
    await tester.enterText(find.byType(TextFormField).at(1), 'Demo@123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DashboardSkeleton), findsOneWidget);
    expect(find.text('0 ₫'), findsNothing);
    expect(app.transactions.hasLoaded, isFalse);
    rows.gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(DashboardSkeleton), findsNothing);
    expect(find.text('Số dư'), findsOneWidget);
    expect(app.transactions.totals.expense, 500);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'visible sorting and removable chips keep independent filter state',
    (tester) async {
      final app = await pumpTestApp(
        tester,
        rows: [
          entry(1, 500),
          entry(2, 200, category: 'Đi lại'),
        ],
      );
      await loginDemo(tester);
      await tester.tap(find.text('Giao dịch').last);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Xóa tìm kiếm'), findsNothing);
      await tester.enterText(find.byType(TextField).first, 'an uong');
      await tester.pump(const Duration(milliseconds: 301));
      await tester.pumpAndSettle();
      expect(find.text('Tìm: an uong'), findsOneWidget);
      expect(app.transactions.visible, hasLength(1));
      await tester.tap(find.byTooltip('Bỏ tìm kiếm'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Chi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<SortOption>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiền giảm dần').last);
      await tester.pumpAndSettle();
      expect(app.transactions.sort, SortOption.amountDesc);
      expect(app.transactions.visible.map((row) => row.id), [1, 2]);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ăn uống').last);
      await tester.pumpAndSettle();
      expect(app.transactions.visible, hasLength(1));
      await tester.tap(find.byTooltip('Bỏ lọc danh mục'));
      await tester.pumpAndSettle();
      expect(app.transactions.categoryFilter, isNull);
      expect(app.transactions.typeFilter, TxType.expense);
      expect(app.transactions.sort, SortOption.amountDesc);
      expect(find.text('2 giao dịch'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'date and category share a row only when content and text size allow',
    (tester) async {
      final date = TextEditingController(text: '28/10/2026');
      addTearDown(date.dispose);
      Future<void> render(double width, double scale) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: width,
                    child: AdaptiveTransactionFields(
                      type: TxType.expense,
                      category: 'Ăn uống',
                      date: DateTime(2026, 10, 28),
                      dateText: date,
                      onCategoryChanged: (_) {},
                      onPickDate: () {},
                      enabled: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await render(600, 1);
      var category = tester.getRect(
        find.byType(DropdownButtonFormField<String>),
      );
      var dateRect = tester.getRect(find.byType(TextFormField));
      expect(dateRect.top, category.top);
      expect(dateRect.left, greaterThan(category.left));
      for (final (width, scale) in [(360.0, 1.0), (600.0, 2.0)]) {
        await render(width, scale);
        category = tester.getRect(find.byType(DropdownButtonFormField<String>));
        dateRect = tester.getRect(find.byType(TextFormField));
        expect(dateRect.top, greaterThanOrEqualTo(category.bottom));
        expect(tester.takeException(), isNull);
      }
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'detail reads a long amount and note, with a visible edit action at text $scale',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpTestApp(
          tester,
          size: const Size(360, 640),
          rows: [entry(1, 999999999999, note: 'Ghi chú dài tiếng Việt. ' * 8)],
        );
        await loginDemo(tester);
        final navigator = tester.state<NavigatorState>(
          find.byType(Navigator).first,
        );
        unawaited(
          navigator.pushNamed(AppRoutes.transactionDetail, arguments: 1),
        );
        await tester.pumpAndSettle();
        expect(find.byTooltip('Sửa giao dịch').hitTestable(), findsOneWidget);
        expect(find.text('−999.999.999.999 ₫'), findsOneWidget);
        final scrollable = find
            .descendant(
              of: find.byType(TransactionDetailScreen),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.widgetWithText(OutlinedButton, 'Xóa giao dịch'),
          400,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _DelayedRows extends FakeTransactions {
  _DelayedRows(super.initial);
  final gate = Completer<void>();
  @override
  Future<List<FinanceTransaction>> getAll(int userId) async {
    await gate.future;
    return super.getAll(userId);
  }
}
