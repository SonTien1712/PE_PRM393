import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  static String generateSalt([int length = 16]) {
    final random = Random.secure();
    return base64UrlEncode(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static String hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  static bool verify(String password, String salt, String expectedHash) =>
      hash(password, salt) == expectedHash;
}
