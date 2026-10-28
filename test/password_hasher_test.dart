import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pe_prm393_de190630/core/password_hasher.dart';

void main() {
  test('salts contain 16 random bytes and create distinct password hashes', () {
    final first = PasswordHasher.generateSalt();
    final second = PasswordHasher.generateSalt();
    expect(base64Url.decode(first), hasLength(16));
    expect(base64Url.decode(second), hasLength(16));
    expect(first, isNot(second));
    expect(
      PasswordHasher.hash('demo-password1', first),
      isNot(PasswordHasher.hash('demo-password1', second)),
    );
  });

  test('verification accepts the password and rejects a different one', () {
    final salt = PasswordHasher.generateSalt();
    final hashed = PasswordHasher.hash('correct-password1', salt);
    expect(PasswordHasher.verify('correct-password1', salt, hashed), isTrue);
    expect(PasswordHasher.verify('wrong-password1', salt, hashed), isFalse);
    expect(
      PasswordHasher.verify('correct-password1', 'other-salt', hashed),
      isFalse,
    );
  });
}
