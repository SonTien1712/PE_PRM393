import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pe_prm393_de190630/core/amount_input_formatter.dart';

void main() {
  const original = TextEditingValue(
    text: '1200',
    selection: TextSelection(baseOffset: 1, extentOffset: 3),
    composing: TextRange(start: 0, end: 1),
  );

  test('allows empty input and a complete twelve-digit edit', () {
    for (final value in ['', '1', '999999999999']) {
      final edit = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
      expect(amountInputFormatter.formatEditUpdate(original, edit), same(edit));
    }
  });

  for (final invalid in [
    '-5',
    '+5',
    '1,5',
    '1.5',
    'abc',
    '１２３',
    '1234567890123',
  ]) {
    test(
      'rejects the whole "$invalid" paste and preserves selection/composing',
      () {
        final edit = TextEditingValue(
          text: invalid,
          selection: TextSelection.collapsed(offset: invalid.length),
        );
        expect(
          amountInputFormatter.formatEditUpdate(original, edit),
          same(original),
        );
      },
    );
  }
}
