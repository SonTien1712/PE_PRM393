import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pe_prm393_de190630/app.dart';
import 'package:pe_prm393_de190630/core/app_routes.dart';
import 'package:pe_prm393_de190630/data/app_database.dart';
import 'package:pe_prm393_de190630/data/csv_export_service.dart';
import 'package:pe_prm393_de190630/data/repositories/budget_repository.dart';
import 'package:pe_prm393_de190630/data/repositories/transaction_repository.dart';
import 'package:pe_prm393_de190630/data/repositories/user_repository.dart';
import 'package:pe_prm393_de190630/data/session_storage.dart';
import 'package:pe_prm393_de190630/providers/auth_provider.dart';
import 'package:pe_prm393_de190630/providers/transaction_provider.dart';
import 'package:pe_prm393_de190630/screens/budget_screen.dart';
import 'package:pe_prm393_de190630/screens/home_shell.dart';
import 'package:pe_prm393_de190630/screens/transaction_detail_screen.dart';
import 'package:pe_prm393_de190630/screens/transaction_form_screen.dart';
import 'package:pe_prm393_de190630/widgets/info_banner.dart';
import 'package:pe_prm393_de190630/widgets/mobile_app_frame.dart';
import 'package:pe_prm393_de190630/widgets/transaction_tile.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Windows native mobile frame, SQLite CRUD, budget, CSV and reopen',
    (tester) async {
      await initializeDateFormatting('vi_VN');
      sqfliteFfiInit();
      final temporary = await Directory.systemTemp.createTemp(
        'finance_native_test_',
      );
      final dbPath = '${temporary.path}/finance_tracker.db';
      var database = await AppDatabase.open(
        path: dbPath,
        factory: databaseFactoryFfi,
      );
      final auth = AuthProvider(UserRepository(database), _MemorySession());
      final rows = TransactionRepository(database);
      final budgets = BudgetRepository(database);
      final provider = TransactionProvider(rows, budgets);
      final capture = GlobalKey();
      const evidence = String.fromEnvironment('EVIDENCE_DIR');
      final captureDirectory = evidence.isEmpty
          ? temporary
          : Directory(evidence);
      await captureDirectory.create(recursive: true);
      Future<void> screenshot(String name) async {
        await tester.pumpAndSettle();
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        await File('${captureDirectory.path}/$name.png')
            .writeAsBytes(png.buffer.asUint8List());
        image.dispose();
      }

      try {
        await tester.pumpWidget(
          RepaintBoundary(
            key: capture,
            child: MultiProvider(
              providers: [
                Provider(create: (_) => CsvExportService()),
                ChangeNotifierProvider<AuthProvider>(create: (_) => auth),
                ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
                  create: (_) => provider,
                  update: (_, auth, previous) {
                    previous!.setUser(auth.currentUser?.id);
                    return previous;
                  },
                ),
              ],
              child: const App(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await screenshot('windows-login');
        await tester.enterText(find.byType(TextFormField).at(0), 'demo1');
        await tester.enterText(find.byType(TextFormField).at(1), 'wrong123');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.byType(InfoBanner), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).at(0))
              .controller!
              .text,
          'demo1',
        );
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).at(1))
              .controller!
              .text,
          isEmpty,
        );
        await screenshot('windows-login-error');
        final passwordField = find.byType(TextFormField).at(1);
        // The native binding retains focusedEditable after the app unfocuses.
        // Tapping reopens the real text input connection before re-entering.
        await tester.ensureVisible(passwordField);
        await tester.tap(passwordField);
        await tester.pumpAndSettle();
        await tester.enterText(passwordField, 'Demo@123');
        expect(
          tester.widget<TextFormField>(passwordField).controller!.text.length,
          8,
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(
          auth.currentUser,
          isNotNull,
          reason: 'Login failed: ${auth.errorMessage}; busy: ${auth.isBusy}',
        );
        expect(find.byType(HomeShell), findsOneWidget);
        final viewport = MediaQuery.of(tester.element(find.byType(HomeShell)))
            .size;
        if (tester.view.physicalSize.width / tester.view.devicePixelRatio >=
            600) {
          expect(viewport.width, 430);
        }
        final navigator = tester.state<NavigatorState>(
          find.byType(Navigator).first,
        );
        unawaited(navigator.pushNamed(AppRoutes.budget));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, '1000');
        await screenshot('windows-budget');
        await tester.tap(find.widgetWithText(FilledButton, 'Lưu ngân sách'));
        await tester.pumpAndSettle();
        expect(find.byType(BudgetScreen), findsNothing);
        expect(provider.monthBudget!.limitAmount, 1000);
        await tester.pump(const Duration(seconds: 5));
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, '900');
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ăn uống').last);
        await tester.pumpAndSettle();
        await screenshot('windows-form');
        await tester.tap(find.widgetWithText(FilledButton, 'Lưu giao dịch'));
        await tester.pumpAndSettle();
        expect(find.byType(TransactionFormScreen), findsNothing);
        expect(provider.totals.expense, 900);
        expect(provider.monthTotals.expense, 900);
        expect(find.text('Sắp vượt ngân sách tháng (90%)'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await screenshot('windows-dashboard');
        await tester.tap(find.text('Giao dịch').last);
        await tester.pumpAndSettle();
        await screenshot('windows-list');
        await tester.tap(find.byType(TransactionTile).first);
        await tester.pumpAndSettle();
        expect(find.byType(TransactionDetailScreen), findsOneWidget);
        expect(find.byTooltip('Sửa giao dịch').hitTestable(), findsOneWidget);
        await screenshot('windows-detail');
        navigator.pop();
        await tester.pumpAndSettle();
        final csv = await provider.buildCsv();
        final saved = await CsvExportService(
          desktop: true,
          directory: () async => temporary,
        ).export(csv, isCurrent: () => true);
        expect((await File(saved!).readAsBytes()).take(3), [0xEF, 0xBB, 0xBF]);
        expect(
          await File(saved).readAsString(),
          contains('expense,Ăn uống,900'),
        );
        expect(find.byType(MobileAppFrame), findsOneWidget);
        expect(tester.takeException(), isNull);
        final month = provider.selectedMonthKey;
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await database.close();
        database = await AppDatabase.open(
          path: dbPath,
          factory: databaseFactoryFfi,
        );
        expect(await TransactionRepository(database).getAll(1), hasLength(1));
        expect(
          (await BudgetRepository(database).getForMonth(1, month))!.limitAmount,
          1000,
        );
        await File('${captureDirectory.path}/windows-smoke.json').writeAsString(
          jsonEncode({
            'result': 'passed',
            'capturedAt': DateTime.now().toIso8601String(),
            'viewportWidth': viewport.width,
            'viewportHeight': viewport.height,
            'database': 'isolated temporary SQLite file',
            'native': true,
            'verified': [
              'login',
              'inline login error, retained username and cleared password',
              'mobile frame',
              'budget save',
              'transaction insert',
              '90% alert',
              'monthly SQL totals',
              'transaction detail and visible edit action',
              'CSV UTF-8 BOM',
              'SQLite close/reopen',
            ],
            'notVerified': [
              'process restart/session persistence',
              'Android share sheet',
              'release process startup',
            ],
          }),
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await database.close();
        if (!path.isWithin(
              Directory.systemTemp.absolute.path,
              temporary.absolute.path,
            ) ||
            !path.basename(temporary.path).startsWith('finance_native_test_')) {
          throw StateError(
            'Refusing to remove a directory outside the native test workspace.',
          );
        }
        await temporary.delete(recursive: true);
      }
    },
  );
}

class _MemorySession implements SessionStorage {
  SessionData? _session;
  @override
  Future<SessionData?> read() async => _session;
  @override
  Future<void> save(int userId) async {
    _session = SessionData(userId: userId, createdAt: DateTime.now());
  }

  @override
  Future<void> clear() async {
    _session = null;
  }
}
