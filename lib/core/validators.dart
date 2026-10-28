import '../data/models/finance_transaction.dart';
import 'categories.dart';
import 'constants.dart';

String? validateLoginUsername(String? value) =>
    value == null || value.trim().isEmpty
    ? 'Vui lòng nhập tên đăng nhập'
    : null;

String? validateLoginPassword(String? value) =>
    value == null || value.isEmpty ? 'Vui lòng nhập mật khẩu' : null;

String? validateUsername(String? value) =>
    RegExp(r'^[a-z0-9_]{3,30}$').hasMatch((value ?? '').trim().toLowerCase())
    ? null
    : 'Tên đăng nhập 3–30 ký tự: chữ, số, dấu gạch dưới';

String? validatePassword(String? value) {
  final password = value ?? '';
  return password.length >= 6 &&
          password.contains(RegExp(r'[a-zA-Z]')) &&
          password.contains(RegExp(r'[0-9]'))
      ? null
      : 'Mật khẩu tối thiểu 6 ký tự, gồm chữ và số';
}

String? validateConfirmPassword(String? value, String password) =>
    value == password ? null : 'Mật khẩu xác nhận không khớp';

String? validateDisplayName(String? value) {
  final name = (value ?? '').trim();
  return name.isNotEmpty && name.length <= 40
      ? null
      : 'Vui lòng nhập tên hiển thị (tối đa 40 ký tự)';
}

String? validateAmount(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Vui lòng nhập số tiền';
  if (!RegExp(r'^[0-9]+$').hasMatch(text)) return 'Số tiền không hợp lệ';
  final amount = int.tryParse(text);
  if (amount == null || amount > maxAmount) return 'Số tiền quá lớn';
  if (amount <= 0) return 'Số tiền phải lớn hơn 0';
  return null;
}

String? validateCategory(String? value, TxType type) {
  if (value == null || value.isEmpty) return 'Vui lòng chọn danh mục';
  return categoriesFor(type).contains(value) ? null : 'Danh mục không hợp lệ';
}

String? validateDate(DateTime? value, {DateTime? today}) {
  if (value == null) return 'Vui lòng chọn ngày';
  final current = today ?? DateTime.now();
  final selectedDay = DateTime(value.year, value.month, value.day);
  final currentDay = DateTime(current.year, current.month, current.day);
  return selectedDay.isAfter(currentDay)
      ? 'Không được chọn ngày trong tương lai'
      : null;
}

/// Parses only a real, canonical yyyy-MM-dd calendar date.
DateTime? parseStorageDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null || parsed.toIso8601String().substring(0, 10) != value) {
    return null;
  }
  return parsed;
}

String? validateNote(String? value) =>
    value != null && value.length > 200 ? 'Ghi chú tối đa 200 ký tự' : null;

String? validateBudgetLimit(String? value) {
  final amount = int.tryParse((value ?? '').trim());
  if (amount == null || amount <= 0) return 'Hạn mức phải lớn hơn 0';
  if (amount > maxAmount) return 'Số tiền quá lớn';
  return null;
}
