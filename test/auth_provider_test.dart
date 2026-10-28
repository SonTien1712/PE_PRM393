import 'package:flutter_test/flutter_test.dart';
import 'package:pe_prm393_de190630/data/session_storage.dart';
import 'package:pe_prm393_de190630/providers/auth_provider.dart';

import 'helpers/fakes.dart';

void main() {
  final now = DateTime(2026, 10, 28, 12);
  for (final age in [const Duration(days: 7), const Duration(seconds: -1)]) {
    test('restoration rejects session age $age and clears it', () async {
      final session = FakeSession(
        SessionData(userId: 1, createdAt: now.subtract(age)),
      );
      final auth = AuthProvider(FakeUsers(), session, now: () => now);
      addTearDown(auth.dispose);
      expect(await auth.restoreSession(), isFalse);
      expect(auth.currentUser, isNull);
      expect(session.clearCalls, 1);
      expect(session.data, isNull);
    });
  }

  test('just under seven days restores an existing user', () async {
    final session = FakeSession(
      SessionData(
        userId: 1,
        createdAt: now
            .subtract(const Duration(days: 7))
            .add(const Duration(milliseconds: 1)),
      ),
    );
    final auth = AuthProvider(FakeUsers(), session, now: () => now);
    addTearDown(auth.dispose);
    expect(await auth.restoreSession(), isTrue);
    expect(auth.currentUser?.id, 1);
    expect(session.clearCalls, 0);
  });

  test(
    'a session read failure reports once without clearing saved keys',
    () async {
      final original = SessionData(userId: 1, createdAt: now);
      final session = FakeSession(original)..failRead = true;
      final auth = AuthProvider(FakeUsers(), session, now: () => now);
      addTearDown(auth.dispose);
      expect(await auth.restoreSession(), isFalse);
      expect(
        auth.errorMessage,
        'Không đọc được phiên đăng nhập. Vui lòng đăng nhập lại.',
      );
      expect(session.clearCalls, 0);
      expect(session.data, same(original));
      auth.clearError();
      expect(auth.errorMessage, isNull);
    },
  );
}
