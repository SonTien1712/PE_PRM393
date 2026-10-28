import '../data/models/finance_transaction.dart';

const expenseCategories = [
  'Ăn uống',
  'Đi lại',
  'Nhà ở',
  'Mua sắm',
  'Giải trí',
  'Sức khỏe',
  'Giáo dục',
  'Khác',
];
const incomeCategories = ['Lương', 'Thưởng', 'Đầu tư', 'Khác'];

List<String> categoriesFor(TxType type) =>
    type == TxType.income ? incomeCategories : expenseCategories;
