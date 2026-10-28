import 'package:intl/intl.dart';

final _numberFormat = NumberFormat.decimalPattern('vi_VN');

String formatVnd(int value) => '${_numberFormat.format(value)} ₫';

int? parseAmountOrNull(String value) => int.tryParse(value.trim());
