import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pe_prm393_de190630/core/app_routes.dart';
import 'package:pe_prm393_de190630/data/models/budget.dart';
import 'package:pe_prm393_de190630/screens/budget_screen.dart';
import 'package:pe_prm393_de190630/screens/home_shell.dart';

import 'helpers/app_harness.dart';
import 'helpers/fakes.dart';

void main() {
  setUpAll(() => initializeDateFormatting('vi_VN'));

  Future<void> openBudget(WidgetTester tester) async {
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    unawaited(navigator.pushNamed(AppRoutes.budget));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'budget commit and refresh failure closes once, retries reads only',
    (tester) async {
      final budgets = FakeBudgets();
      final app = await pumpTestApp(tester, budgets: budgets);
      await loginDemo(tester);
      await openBudget(tester);
      await tester.enterText(find.byType(TextFormField).first, '1000');
      budgets.failReadsAfterWrite = true;
      final save = find.widgetWithText(FilledButton, 'Lưu ngân sách');
      await tester.tap(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(budgets.writes, 1);
      expect(budgets.rows['1:2026-10']!.limitAmount, 1000);
      expect(find.byType(BudgetScreen), findsNothing);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(
        find.text(
          'Đã lưu ngân sách, nhưng chưa tải lại được dữ liệu. Vui lòng thử tải lại.',
        ),
        findsOneWidget,
      );
      expect(app.transactions.needsRefresh, isTrue);
      budgets.failReads = false;
      await tester.tap(find.text('Thử tải lại'));
      await tester.pumpAndSettle();
      expect(app.transactions.needsRefresh, isFalse);
      expect(budgets.writes, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'budget deletion requires confirmation, cancellation keeps the budget',
    (tester) async {
      final budgets = FakeBudgets()
        ..rows['1:2026-10'] = const Budget(
          userId: 1,
          month: '2026-10',
          limitAmount: 1000,
        );
      final app = await pumpTestApp(tester, budgets: budgets);
      await loginDemo(tester);
      await openBudget(tester);
      final delete = find.widgetWithText(OutlinedButton, 'Xóa ngân sách');
      await tester.tap(delete);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Hủy'),
        ),
      );
      await tester.pumpAndSettle();
      expect(budgets.writes, 0);
      expect(find.byType(BudgetScreen), findsOneWidget);
      await tester.tap(delete);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Xóa'),
        ),
      );
      await tester.pumpAndSettle();
      expect(budgets.writes, 1);
      expect(budgets.rows, isEmpty);
      expect(app.transactions.monthBudget, isNull);
      expect(find.byType(BudgetScreen), findsNothing);
      expect(find.text('Đã xóa ngân sách'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
