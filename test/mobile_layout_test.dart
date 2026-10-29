import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pe_prm393_de190630/core/app_routes.dart';
import 'package:pe_prm393_de190630/data/models/budget.dart';
import 'package:pe_prm393_de190630/data/models/finance_transaction.dart';
import 'package:pe_prm393_de190630/screens/home_shell.dart';
import 'package:pe_prm393_de190630/screens/transaction_form_screen.dart';
import 'package:pe_prm393_de190630/widgets/form_footer.dart';
import 'package:pe_prm393_de190630/widgets/mobile_app_frame.dart';
import 'package:pe_prm393_de190630/widgets/info_banner.dart';

import 'helpers/app_harness.dart';
import 'helpers/fakes.dart';
import 'helpers/load_fonts.dart';

List<FinanceTransaction> get fixtureRows => [
  for (final (id, type, amount, category, date, note) in [
    (1, TxType.income, 10000000, 'Lương', '2026-10-25', 'Lương tháng 10'),
    (2, TxType.expense, 1500000, 'Nhà ở', '2026-10-02', 'Tiền thuê phòng'),
    (3, TxType.expense, 2220000, 'Mua sắm', '2026-10-26', 'Đồ dùng cá nhân'),
    (4, TxType.expense, 80000, 'Ăn uống', '2026-10-28', 'Bữa trưa cùng bạn'),
  ])
    FinanceTransaction(
      id: id,
      userId: 1,
      type: type,
      amount: amount,
      category: category,
      date: date,
      note: note,
      createdAt: '${date}T08:00:00',
    ),
];

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN');
    await loadAppFonts();
  });

  testWidgets(
    'mobile form has labelled controls and sufficient touch targets',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await pumpTestApp(tester, size: const Size(360, 640));
        await loginDemo(tester);
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final size in [
    const Size(360, 640),
    const Size(412, 915),
    const Size(768, 1024),
    const Size(1280, 720),
    const Size(1440, 900),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('mobile viewport and large amounts at $size / text $scale', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final app = await pumpTestApp(
          tester,
          size: size,
          rows: [
            FinanceTransaction(
              id: 1,
              userId: 1,
              type: TxType.income,
              amount: 999999999999,
              category: 'Lương',
              date: '2026-10-01',
              note: 'Ghi chú dài ' * 16,
              createdAt: '2026-10-01T08:00:00',
            ),
          ],
        );
        await loginDemo(tester);
        final framed = size.width >= 600 && size.height >= 440;
        final media = MediaQuery.of(tester.element(find.byType(HomeShell)));
        expect(media.size.width, framed ? 430 : size.width);
        expect(find.byKey(MobileAppFrame.viewportKey), findsOneWidget);
        expect(app.transactions.totals.income, 999999999999);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Giao dịch').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        expect(find.byType(FormFooter), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'resizing through the frame breakpoint preserves route and input',
    (tester) async {
      await pumpTestApp(tester);
      await loginDemo(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '123456');
      tester.testTextInput.hide();
      for (final size in [const Size(1280, 720), const Size(360, 640)]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(find.byType(TransactionFormScreen), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).first)
              .controller!
              .text,
          '123456',
        );
        expect(
          tester.state<NavigatorState>(find.byType(Navigator).first).canPop(),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('keyboard and failure feedback leave the save action visible', (
    tester,
  ) async {
    await pumpTestApp(tester, size: const Size(360, 640));
    await loginDemo(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, 'Lưu giao dịch');
    expect(tester.getRect(save).bottom, lessThanOrEqualTo(360));
    ScaffoldMessenger.of(tester.element(find.byType(TransactionFormScreen)))
        .showSnackBar(
          const SnackBar(
            content: Text('Không thể lưu giao dịch. Vui lòng thử lại.'),
          ),
        );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(SnackBar)).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(FormFooter)).top + 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('date picker and menu remain inside the Windows phone viewport', (
    tester,
  ) async {
    await pumpTestApp(tester, size: const Size(1280, 900));
    await loginDemo(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    final date = find.widgetWithText(TextFormField, 'Ngày giao dịch');
    await tester.ensureVisible(date);
    await tester.tap(date);
    await tester.pumpAndSettle();
    final viewport = tester.getRect(find.byKey(MobileAppFrame.viewportKey));
    final dialog = tester.getRect(find.byType(DatePickerDialog));
    expect(dialog.left, greaterThanOrEqualTo(viewport.left));
    expect(dialog.right, lessThanOrEqualTo(viewport.right));
    expect(dialog.top, greaterThanOrEqualTo(viewport.top));
    expect(dialog.bottom, lessThanOrEqualTo(viewport.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('golden mobile screens with the bundled Vietnamese font', (
    tester,
  ) async {
    final budgets = FakeBudgets()
      ..rows['1:2026-10'] = const Budget(
        userId: 1,
        month: '2026-10',
        limitAmount: 4000000,
      );
    final app = await pumpTestApp(
      tester,
      size: const Size(1280, 900),
      rows: fixtureRows,
      budgets: budgets,
    );
    await expectLater(
      find.byType(MobileAppFrame),
      matchesGoldenFile('goldens/windows_mobile_login.png'),
    );
    await loginDemo(tester);
    await expectLater(
      find.byType(MobileAppFrame),
      matchesGoldenFile('goldens/windows_mobile_dashboard.png'),
    );
    await tester.tap(find.text('Giao dịch').last);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MobileAppFrame),
      matchesGoldenFile('goldens/windows_mobile_list.png'),
    );
    final detailNavigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    unawaited(
      detailNavigator.pushNamed(AppRoutes.transactionDetail, arguments: 4),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MobileAppFrame),
      matchesGoldenFile('goldens/windows_mobile_detail.png'),
    );
    detailNavigator.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MobileAppFrame),
      matchesGoldenFile('goldens/windows_mobile_form.png'),
    );
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pop();
    await tester.pumpAndSettle();
    unawaited(navigator.pushNamed(AppRoutes.budget));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MobileAppFrame),
      matchesGoldenFile('goldens/windows_mobile_budget.png'),
    );
    navigator.pop();
    await tester.pumpAndSettle();
    await app.auth.logout();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'demo1');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(InfoBanner));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MobileAppFrame),
      matchesGoldenFile('goldens/windows_mobile_login_error.png'),
    );
    await tester.ensureVisible(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MobileAppFrame),
      matchesGoldenFile('goldens/windows_mobile_register.png'),
    );
    expect(tester.takeException(), isNull);
  });
}
