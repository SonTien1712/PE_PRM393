import 'package:flutter_test/flutter_test.dart';
import 'package:pe_prm393_de190630/core/text_utils.dart';

void main() {
  group('Vietnamese search normalization', () {
    test('strips precomposed accents and handles uppercase and padding', () {
      expect(normalizeVi('Ăn uống'), 'an uong');
      expect(normalizeVi('Đi lại'), 'di lai');
      expect(normalizeVi('  SỨC KHỎE  '), 'suc khoe');
      expect(normalizeVi('Đầu tư'), 'dau tu');
      expect(normalizeVi(''), '');
    });

    test('decomposed and precomposed text normalize identically', () {
      expect(normalizeVi('A\u0306n uo\u0302\u0301ng'), 'an uong');
      expect(normalizeVi('A\u0306n uo\u0302\u0301ng'), normalizeVi('Ăn uống'));
      expect(normalizeVi('e\u0302\u0301'), normalizeVi('ế'));
    });

    test('all Vietnamese vowel groups and đ keep the correct base letter', () {
      const accented = [
        'àáạảãâầấậẩẫăằắặẳẵ',
        'èéẹẻẽêềếệểễ',
        'ìíịỉĩ',
        'òóọỏõôồốộổỗơờớợởỡ',
        'ùúụủũưừứựửữ',
        'ỳýỵỷỹ',
        'đ',
      ];
      const base = ['a', 'e', 'i', 'o', 'u', 'y', 'd'];
      for (var index = 0; index < accented.length; index++) {
        expect(
          normalizeVi(accented[index]),
          base[index] * accented[index].length,
        );
      }
    });
  });
}
