import 'package:pe_prm393_de190630/core/month_utils.dart';
import 'package:pe_prm393_de190630/data/models/budget.dart';
import 'package:pe_prm393_de190630/data/models/finance_transaction.dart';

const demoPassword = 'Demo@2026';
const demoUsernames = ['presenter_demo', 'overbudget_demo', 'empty_demo'];

class DemoAccount {
  const DemoAccount({
    required this.username,
    required this.displayName,
    required this.transactions,
    required this.budgets,
  });

  final String username;
  final String displayName;
  final List<FinanceTransaction> transactions;
  final List<Budget> budgets;
}

/// Dates follow the presentation month; current-month days never exceed asOf.
List<DemoAccount> buildDemoDataset(DateTime asOf) {
  final today = DateTime(asOf.year, asOf.month, asOf.day);
  final main = <FinanceTransaction>[];
  final mainBudgets = <Budget>[];

  DateTime day(int monthsBack, int preferredDay) {
    final month = DateTime(today.year, today.month - monthsBack);
    final lastDay = monthsBack == 0
        ? today.day
        : DateTime(month.year, month.month + 1, 0).day;
    return DateTime(month.year, month.month, preferredDay.clamp(1, lastDay));
  }

  FinanceTransaction row(
    int monthsBack,
    int preferredDay,
    TxType type,
    int amount,
    String category,
    String note,
  ) {
    final date = day(monthsBack, preferredDay);
    return FinanceTransaction(
      userId: 0,
      type: type,
      amount: amount,
      category: category,
      date: '${monthKey(date)}-${date.day.toString().padLeft(2, '0')}',
      note: note,
      createdAt: DateTime(date.year, date.month, date.day, 9).toIso8601String(),
    );
  }

  void add(
    int back,
    int date,
    TxType type,
    int amount,
    String category,
    String note,
  ) {
    main.add(row(back, date, type, amount, category, note));
  }

  const income = TxType.income;
  const expense = TxType.expense;

  // Current month: income 21m, expense 7.9m, budget 10m (79%).
  add(0, 1, income, 18000000, 'Lương', 'Lương tháng hiện tại');
  add(0, 10, income, 1500000, 'Thưởng', 'Thưởng hoàn thành dự án mobile');
  add(0, 12, income, 500000, 'Đầu tư', 'Lãi tiết kiệm');
  add(0, 18, income, 1000000, 'Khác', 'Thiết kế giao diện freelance');
  add(0, 2, expense, 3000000, 'Nhà ở', 'Tiền thuê phòng và điện nước');
  add(0, 3, expense, 300000, 'Ăn uống', 'Ăn sáng, cà phê cùng nhóm');
  add(0, 5, expense, 400000, 'Đi lại', 'Xăng xe và gửi xe');
  add(0, 9, expense, 900000, 'Mua sắm', 'Bàn phím phục vụ học tập');
  add(0, 13, expense, 450000, 'Sức khỏe', 'Khám sức khỏe định kỳ');
  add(0, 16, expense, 650000, 'Giáo dục', 'Khóa Flutter\nTài liệu SQLite');
  add(0, 19, expense, 300000, 'Giải trí', 'Xem phim cuối tuần');
  add(0, 21, expense, 450000, 'Ăn uống', 'Bữa trưa "nhóm Flutter"');
  add(
    0,
    26,
    expense,
    1250000,
    'Ăn uống',
    'Ca\u0300 phe\u0302 va\u0300 a\u0306n to\u0302\u0301i với bạn',
  );
  add(0, 27, expense, 200000, 'Khác', '=SUM(1,2) — ghi chú kiểm tra CSV');

  // Previous month: income 20m, expense 9.6m, budget 10m (96%).
  add(1, 1, income, 17000000, 'Lương', 'Lương tháng trước');
  add(1, 15, income, 2000000, 'Thưởng', 'Thưởng hiệu suất');
  add(1, 20, income, 1000000, 'Đầu tư', 'Lãi đầu tư tháng trước');
  for (final item in [
    (2, 3000000, 'Nhà ở', 'Tiền nhà tháng trước'),
    (6, 2400000, 'Ăn uống', 'Chi ăn uống tháng trước'),
    (9, 600000, 'Đi lại', 'Chi di chuyển tháng trước'),
    (12, 1000000, 'Mua sắm', 'Đồ dùng cá nhân'),
    (16, 500000, 'Giải trí', 'Du lịch ngắn ngày'),
    (19, 400000, 'Sức khỏe', 'Thuốc và kiểm tra sức khỏe'),
    (23, 1500000, 'Giáo dục', 'Học phí khóa học'),
    (27, 200000, 'Khác', 'Chi phí phát sinh'),
  ]) {
    add(1, item.$1, expense, item.$2, item.$3, item.$4);
  }

  // Two months ago: income 16.5m, expense 10.8m, budget 10m (108%).
  add(2, 1, income, 16000000, 'Lương', 'Lương hai tháng trước');
  add(2, 12, income, 500000, 'Đầu tư', 'Lãi tiết kiệm hai tháng trước');
  for (final item in [
    (2, 3000000, 'Nhà ở', 'Tiền nhà hai tháng trước'),
    (5, 2800000, 'Ăn uống', 'Chi ăn uống hai tháng trước'),
    (8, 800000, 'Đi lại', 'Vé xe và xăng'),
    (11, 1200000, 'Mua sắm', 'Đồ dùng học tập'),
    (15, 700000, 'Giải trí', 'Dã ngoại cùng lớp'),
    (18, 400000, 'Sức khỏe', 'Chăm sóc sức khỏe'),
    (22, 1600000, 'Giáo dục', 'Sách và học phí'),
    (27, 300000, 'Khác', 'Chi phí phát sinh hai tháng trước'),
  ]) {
    add(2, item.$1, expense, item.$2, item.$3, item.$4);
  }
  for (var back = 0; back < 3; back++) {
    mainBudgets.add(
      Budget(userId: 0, month: monthKey(day(back, 1)), limitAmount: 10000000),
    );
  }

  return [
    DemoAccount(
      username: demoUsernames[0],
      displayName: 'Minh Anh Demo',
      transactions: List.unmodifiable(main),
      budgets: List.unmodifiable(mainBudgets),
    ),
    DemoAccount(
      username: demoUsernames[1],
      displayName: 'Vượt chi Demo',
      transactions: [
        row(0, 1, income, 5000000, 'Lương', 'Thu nhập của tài khoản thứ hai'),
        row(0, 3, expense, 4000000, 'Nhà ở', 'Tiền thuê căn hộ'),
        row(0, 10, expense, 1500000, 'Mua sắm', 'Sửa máy tính'),
        row(0, 15, expense, 250000, 'Ăn uống', 'Chi ăn uống'),
      ],
      budgets: [
        Budget(userId: 0, month: monthKey(today), limitAmount: 5000000),
      ],
    ),
    DemoAccount(
      username: demoUsernames[2],
      displayName: 'Sổ trống Demo',
      transactions: const [],
      budgets: const [],
    ),
  ];
}
