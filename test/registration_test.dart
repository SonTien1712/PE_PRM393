import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pe_prm393_de190630/core/app_routes.dart';
import 'package:pe_prm393_de190630/data/app_database.dart';
import 'package:pe_prm393_de190630/data/repositories/transaction_repository.dart';
import 'package:pe_prm393_de190630/data/repositories/user_repository.dart';
import 'package:pe_prm393_de190630/providers/auth_provider.dart';
import 'package:pe_prm393_de190630/screens/home_shell.dart';
import 'package:pe_prm393_de190630/screens/register_screen.dart';

import 'helpers/app_harness.dart';
import 'helpers/fakes.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    await initializeDateFormatting('vi_VN');
  });

  test('real registration hashes credentials, logs in, restores and starts with no transactions', () async {
    final db = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    addTearDown(db.close);
    final users = UserRepository(db);
    final session = FakeSession(null);
    final auth = AuthProvider(users, session);
    addTearDown(auth.dispose);
    expect(
      await auth.register('  NEW_USER  ', 'Secret123', ' Nguyễn An '),
      isTrue,
    );
    final id = auth.currentUser!.id;
    expect(auth.currentUser!.username, 'new_user');
    expect(auth.currentUser!.displayName, 'Nguyễn An');
    expect(session.data!.userId, id);
    expect(await TransactionRepository(db).getAll(id), isEmpty);
    final stored = (await db.db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    )).single;
    expect(stored['password_hash'], isNot('Secret123'));
    expect((stored['salt'] as String).isNotEmpty, isTrue);
    await auth.logout();
    expect(await auth.login('NEW_USER', 'Secret123'), isTrue);
    final restored = AuthProvider(users, session);
    addTearDown(restored.dispose);
    expect(await restored.restoreSession(), isTrue);
    expect(restored.currentUser!.id, id);
    await auth.logout();
    expect(await auth.register('new_USER', 'Other123', 'Other'), isFalse);
    expect(auth.errorMessage, 'Tên đăng nhập đã tồn tại');
    expect(auth.registrationCreated, isFalse);
    expect(auth.currentUser, isNull);
  });

  test('session failure after account creation reports creation without repeating registration', () async {
    final users = FakeUsers();
    final auth = AuthProvider(users, _FailingSave());
    addTearDown(auth.dispose);
    expect(await auth.register('new_user', 'Secret123', 'An'), isFalse);
    expect(auth.registrationCreated, isTrue);
    expect(auth.currentUser, isNull);
    expect(
      auth.errorMessage,
      'Đã tạo tài khoản. Vui lòng đăng nhập để tiếp tục.',
    );
    expect(await users.authenticate('new_user', 'Secret123'), isNotNull);
  });

  Future<void> openRegister(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, String username) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Nguyễn An');
    await tester.enterText(fields.at(1), username);
    await tester.enterText(fields.at(2), 'Secret123');
    await tester.enterText(fields.at(3), 'Secret123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'registration opens Home with empty user data and a cleared stack',
    (tester) async {
      final app = await pumpTestApp(tester);
      await openRegister(tester);
      await fill(tester, 'new_user');
      expect(find.byType(HomeShell), findsOneWidget);
      expect(app.auth.currentUser!.username, 'new_user');
      expect(app.transactions.all, isEmpty);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator).first).canPop(),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('duplicate username is inline, editable and can be resubmitted', (
    tester,
  ) async {
    await pumpTestApp(tester);
    await openRegister(tester);
    await fill(tester, 'DEMO1');
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('Tên đăng nhập đã tồn tại'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), 'new_user');
    tester.testTextInput.hide();
    final submit = find.widgetWithText(FilledButton, 'Đăng ký');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('budget route is protected when opened directly', (tester) async {
    await pumpTestApp(tester);
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    unawaited(navigator.pushNamed(AppRoutes.budget));
    await tester.pumpAndSettle();
    expect(find.text('Tên đăng nhập'), findsOneWidget);
    expect(find.text('Hạn mức chi tiêu (₫)'), findsNothing);
    expect(navigator.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });
}

class _FailingSave extends FakeSession {
  _FailingSave() : super(null);
  @override
  Future<void> save(int userId) async =>
      throw StateError('Injected session write failure');
}
