import 'package:flutter/services.dart';

final amountInputFormatter = TextInputFormatter.withFunction((
  oldValue,
  newValue,
) {
  return RegExp(r'^[0-9]{0,12}$').hasMatch(newValue.text) ? newValue : oldValue;
});
