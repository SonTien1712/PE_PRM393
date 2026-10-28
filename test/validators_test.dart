import 'package:flutter_test/flutter_test.dart';
import 'package:pe_prm393_de190630/core/constants.dart';
import 'package:pe_prm393_de190630/core/validators.dart';
import 'package:pe_prm393_de190630/data/models/finance_transaction.dart';

void main() {
  group('amount', () {
    for (final invalid in [
      '',
      'abc',
      '0',
      '-5',
      '+5',
      '1,5',
      '1.5',
      '1000000000000',
    ]) {
      test('rejects "$invalid"', () {
        expect(validateAmount(invalid), isNotNull);
      });
    }
    test('accepts a positive integer and the inclusive maximum', () {
      expect(validateAmount('150000'), isNull);
      expect(validateAmount(maxAmount.toString()), isNull);
    });
    test('handles unparseably large integers safely', () {
      expect(validateAmount('9' * 100), 'Số tiền quá lớn');
    });
  });

  group('category, date, note, and budget', () {
    test('requires a category belonging to the selected type', () {
      expect(validateCategory(null, TxType.income), 'Vui lòng chọn danh mục');
      expect(
        validateCategory('Ăn uống', TxType.income),
        'Danh mục không hợp lệ',
      );
      expect(
        validateCategory('Lương', TxType.expense),
        'Danh mục không hợp lệ',
      );
      expect(validateCategory('Lương', TxType.income), isNull);
      expect(validateCategory('Ăn uống', TxType.expense), isNull);
      expect(validateCategory('Khác', TxType.income), isNull);
    });
    test('requires a date no later than today, ignoring time of day', () {
      final today = DateTime(2026, 10, 28, 10);
      expect(validateDate(null, today: today), 'Vui lòng chọn ngày');
      expect(validateDate(DateTime(2026, 10, 28, 23), today: today), isNull);
      expect(validateDate(DateTime(2026, 10, 27), today: today), isNull);
      expect(
        validateDate(DateTime(2026, 10, 29), today: today),
        'Không được chọn ngày trong tương lai',
      );
    });
    test('stored dates must be canonical and real calendar dates', () {
      expect(parseStorageDate('2024-02-29'), DateTime(2024, 2, 29));
      for (final invalid in [
        '2026-02-29',
        '2026-13-01',
        '2026-1-01',
        '',
        'abc',
      ]) {
        expect(parseStorageDate(invalid), isNull);
      }
    });
    test('note is optional and limited to 200 characters', () {
      expect(validateNote(null), isNull);
      expect(validateNote('x' * 200), isNull);
      expect(validateNote('x' * 201), 'Ghi chú tối đa 200 ký tự');
    });
    test('budget uses positive integer bounds', () {
      for (final invalid in ['', 'abc', '0', '-1', '1.5', '${maxAmount + 1}']) {
        expect(validateBudgetLimit(invalid), isNotNull);
      }
      expect(validateBudgetLimit('$maxAmount'), isNull);
    });
  });

  group('authentication fields', () {
    test('login only requires nonempty fields', () {
      expect(validateLoginUsername('  '), isNotNull);
      expect(validateLoginUsername('demo1'), isNull);
      expect(validateLoginPassword(''), isNotNull);
      expect(validateLoginPassword('abc'), isNull);
    });
    test('registration usernames are normalized and restricted', () {
      expect(validateUsername('  DEMO_1  '), isNull);
      expect(validateUsername('a' * 30), isNull);
      for (final invalid in ['', 'ab', 'a' * 31, 'nguyễn', 'a b', 'abc!']) {
        expect(validateUsername(invalid), isNotNull);
      }
    });
    test(
      'registration requires a letter and number in a long enough password',
      () {
        for (final invalid in ['', 'abc12', 'abcdef', '123456']) {
          expect(validatePassword(invalid), isNotNull);
        }
        expect(validatePassword('Demo@123'), isNull);
        expect(validateConfirmPassword('Demo@123', 'Demo@123'), isNull);
        expect(validateConfirmPassword('different', 'Demo@123'), isNotNull);
      },
    );
    test('display name is trimmed and between one and forty characters', () {
      expect(validateDisplayName('  '), isNotNull);
      expect(validateDisplayName('a' * 41), isNotNull);
      expect(validateDisplayName('  Nguyễn Văn A  '), isNull);
    });
  });
}
