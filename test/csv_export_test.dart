import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pe_prm393_de190630/core/app_exception.dart';
import 'package:pe_prm393_de190630/core/csv_export.dart';
import 'package:pe_prm393_de190630/core/text_utils.dart';
import 'package:pe_prm393_de190630/data/csv_export_service.dart';
import 'package:pe_prm393_de190630/data/models/finance_transaction.dart';
import 'package:pe_prm393_de190630/providers/transaction_provider.dart';

import 'helpers/app_harness.dart';
import 'helpers/fakes.dart';

FinanceTransaction row(
  int id, {
  int user = 1,
  String date = '2026-10-01',
  String? note,
}) => FinanceTransaction(
  id: id,
  userId: user,
  type: TxType.expense,
  amount: 100,
  category: 'Ăn uống',
  date: date,
  note: note,
  createdAt: '${date}T00:00:00',
);

void main() {
  setUpAll(() => initializeDateFormatting('vi_VN'));

  test(
    'CSV uses UTF-8 BOM, chronological order, real line breaks and escaping',
    () {
      final csv = buildTransactionsCsv([
        row(3, date: '2026-10-03', note: '=SUM(A1:A2)'),
        row(2, note: 'Bữa trưa, "ngon"\nxong'),
        row(1),
      ]);
      expect(utf8.encode(csv).take(3), [0xEF, 0xBB, 0xBF]);
      expect(csv, startsWith('\uFEFFid,date,type,category,amount,note\r\n'));
      expect(
        csv.indexOf('1,2026-10-01'),
        lessThan(csv.indexOf('2,2026-10-01')),
      );
      expect(
        csv.indexOf('2,2026-10-01'),
        lessThan(csv.indexOf('3,2026-10-03')),
      );
      expect(csv, contains('"Bữa trưa, ""ngon""\nxong"'));
      expect(csv, contains(",'=SUM(A1:A2)\r\n"));
      expect(csvEscape('@example'), "'@example");
      expect(csvEscape('+1'), "'+1");
      expect(csvEscape('-1'), "'-1");
      expect(csvEscape('Ăn uống'), 'Ăn uống');
    },
  );

  test(
    'provider exports all captured-user rows regardless of active filters',
    () async {
      final provider = TransactionProvider(
        FakeTransactions([row(1), row(2, user: 2)]),
        FakeBudgets(),
      );
      addTearDown(provider.dispose);
      provider.setUser(1);
      await Future<void>.delayed(Duration.zero);
      provider.setSearch('no matches');
      expect(provider.visible, isEmpty);
      final csv = await provider.buildCsv();
      expect(csv, contains('1,2026-10-01'));
      expect(csv, isNot(contains('2,2026-10-01')));
      provider.setUser(2);
      await Future<void>.delayed(Duration.zero);
      expect(await provider.buildCsv(), contains('2,2026-10-01'));
      provider.setUser(null);
      await expectLater(provider.buildCsv(), throwsA(isA<AppException>()));
    },
  );

  test(
    'pending old-user CSV is rejected without changing the new session',
    () async {
      final repository = _PendingExport([row(1)]);
      final provider = TransactionProvider(repository, FakeBudgets());
      addTearDown(provider.dispose);
      provider.setUser(1);
      await Future<void>.delayed(Duration.zero);
      final gate = Completer<List<FinanceTransaction>>();
      repository.gate = gate;
      final csv = provider.buildCsv();
      final assertion = expectLater(csv, throwsA(isA<AppException>()));
      provider.setUser(2);
      await Future<void>.delayed(Duration.zero);
      gate.complete([row(1)]);
      await assertion;
      expect(provider.userId, 2);
      expect(provider.all, isEmpty);
      expect(provider.errorMessage, isNull);
    },
  );

  group('file export', () {
    late Directory directory;
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('finance_csv_test_');
    });
    tearDown(() async {
      await directory.delete(recursive: true);
    });

    test('desktop writes real UTF-8 file, never shares and avoids overwriting a previous export', () async {
      var shares = 0;
      final service = CsvExportService(
        desktop: true,
        directory: () async => directory,
        now: () => DateTime(2026, 10, 28, 12),
        shareFile: (_) async {
          shares++;
        },
      );
      final first = (await service.export(
        '\uFEFFTiếng Việt',
        isCurrent: () => true,
      ))!;
      final second = (await service.export(
        '\uFEFFKhác',
        isCurrent: () => true,
      ))!;
      expect(first, endsWith('finance_export_20261028_120000.csv'));
      expect(second, isNot(first));
      expect(await File(first).readAsBytes(), utf8.encode('\uFEFFTiếng Việt'));
      expect(await File(second).readAsBytes(), utf8.encode('\uFEFFKhác'));
      expect(shares, 0);
    });

    test('mobile writes a temporary CSV before calling share', () async {
      String? shared;
      final service = CsvExportService(
        desktop: false,
        directory: () async => directory,
        shareFile: (file) async {
          expect(await File(file).readAsBytes(), utf8.encode('\uFEFFĐúng'));
          shared = file;
        },
      );
      final output = await service.export('\uFEFFĐúng', isCurrent: () => true);
      expect(shared, output);
      expect(shared, isNotNull);
    });

    test(
      'session change during directory resolution prevents writing or sharing',
      () async {
        var current = true;
        var shares = 0;
        final gate = Completer<Directory>();
        final service = CsvExportService(
          desktop: false,
          directory: () => gate.future,
          shareFile: (_) async {
            shares++;
          },
        );
        final output = service.export('old data', isCurrent: () => current);
        current = false;
        gate.complete(directory);
        expect(await output, isNull);
        expect(await directory.list().toList(), isEmpty);
        expect(shares, 0);
      },
    );

    test(
      'session change during write discards the file and never shares',
      () async {
        var current = true;
        var shares = 0;
        final writing = Completer<void>();
        final release = Completer<void>();
        final service = CsvExportService(
          desktop: false,
          directory: () async => directory,
          writeFile: (file, csv) async {
            writing.complete();
            await release.future;
            await file.writeAsString(csv);
          },
          shareFile: (_) async {
            shares++;
          },
        );
        final output = service.export('old data', isCurrent: () => current);
        await writing.future;
        current = false;
        release.complete();
        expect(await output, isNull);
        expect(await directory.list().toList(), isEmpty);
        expect(shares, 0);
      },
    );

    test('file write failure returns a Vietnamese error and removes partial output', () async {
      final service = CsvExportService(
        desktop: true,
        directory: () async => directory,
        writeFile: (file, csv) async {
          await file.writeAsString('partial');
          throw const FileSystemException('Injected');
        },
      );
      await expectLater(
        service.export('data', isCurrent: () => true),
        throwsA(
          isA<AppException>().having(
            (error) => error.message,
            'message',
            'Không thể xuất file. Vui lòng thử lại.',
          ),
        ),
      );
      expect(await directory.list().toList(), isEmpty);
    });
  });

  testWidgets(
    'CSV menu is available only on the list tab and empty export is explained',
    (tester) async {
      await pumpTestApp(tester);
      await loginDemo(tester);
      await tester.tap(find.byTooltip('Tùy chọn'));
      await tester.pumpAndSettle();
      expect(find.text('Xuất CSV'), findsNothing);
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giao dịch').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tùy chọn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xuất CSV'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có dữ liệu để xuất'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _PendingExport extends FakeTransactions {
  _PendingExport(super.initial);
  Completer<List<FinanceTransaction>>? gate;
  @override
  Future<List<FinanceTransaction>> getAll(int userId) {
    if (userId == 1 && gate != null) return gate!.future;
    return super.getAll(userId);
  }
}
