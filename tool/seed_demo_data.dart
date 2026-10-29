import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pe_prm393_de190630/core/validators.dart';

import 'demo_dataset.dart';
import 'demo_seed_support.dart';

Future<void> main(List<String> arguments) async {
  try {
    await run(arguments);
  } catch (error) {
    stderr.writeln('Không nạp được dữ liệu demo: $error');
    exitCode = 1;
  }
}

Future<void> run(List<String> arguments) async {
  if (arguments.contains('--help')) {
    stdout.writeln('''
dart run tool/seed_demo_data.dart [--apply] [--database PATH] [--as-of yyyy-MM-dd]
  [--backup-dir evidence/local] [--report evidence/demo-data-summary.json]

Mặc định chỉ xem kế hoạch và dữ liệu demo hiện có.
--apply tạo backup SQLite rồi thêm 3 tài khoản demo còn thiếu trong transaction.
Không reset tài khoản đã có, không thay đổi demo1/demo2 hoặc phiên đăng nhập.
Ngày mặc định theo Asia/Saigon (UTC+7). Chạy app một lần để tạo DB trước.
''');
    return;
  }
  var apply = false;
  final options = <String, String>{};
  const valuedOptions = {'--database', '--as-of', '--backup-dir', '--report'};
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (argument == '--apply') {
      apply = true;
    } else if (valuedOptions.contains(argument) &&
        index + 1 < arguments.length) {
      options[argument] = arguments[++index];
    } else {
      throw ArgumentError('Tham số không hợp lệ: $argument. Dùng --help.');
    }
  }
  final now = DateTime.now().toUtc().add(const Duration(hours: 7));
  final today = DateTime(now.year, now.month, now.day);
  final asOf = options['--as-of'] == null
      ? today
      : parseStorageDate(options['--as-of']!);
  if (asOf == null || asOf.isAfter(today) || asOf.isBefore(DateTime(2000, 3))) {
    throw ArgumentError(
      'Ngày trình bày phải hợp lệ, từ 2000-03-01 tới hôm nay.',
    );
  }
  final appData = Platform.environment['APPDATA'];
  final defaultPath = Platform.isWindows && appData != null
      ? path.join(
          appData,
          'com.example',
          'pe_prm393_de190630',
          'finance_tracker.db',
        )
      : null;
  final databasePath = options['--database'] ?? defaultPath;
  if (databasePath == null || !await File(databasePath).exists()) {
    throw StateError(
      'Chưa tìm thấy DB. Mở app một lần hoặc truyền --database PATH.',
    );
  }
  sqfliteFfiInit();
  final database = await databaseFactoryFfiNoIsolate.openDatabase(
    path.normalize(path.absolute(databasePath)),
    options: OpenDatabaseOptions(
      singleInstance: false,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA busy_timeout = 5000');
      },
    ),
  );
  try {
    await validateDemoDatabase(database);
    String? backup;
    List<Map<String, Object?>>? changes;
    if (apply) {
      backup = await backupDemoDatabase(
        database,
        Directory(options['--backup-dir'] ?? 'evidence/local'),
      );
      changes = await seedDemoData(database, asOf);
    }
    final report = {
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'asOf': asOf.toIso8601String().substring(0, 10),
      'database': database.path,
      'applied': apply,
      'backup': backup,
      'changes': changes,
      'plannedAccounts': [
        for (final account in buildDemoDataset(asOf))
          {
            'username': account.username,
            'transactions': account.transactions.length,
            'budgets': account.budgets.length,
          },
      ],
      'actualAccounts': await demoDatabaseSummary(database),
    };
    final json = const JsonEncoder.withIndent('  ').convert(report);
    stdout.writeln(json);
    final reportPath = options['--report'];
    if (reportPath != null) {
      final file = File(reportPath);
      await file.parent.create(recursive: true);
      await file.writeAsString('$json\n', flush: true);
    }
  } finally {
    await database.close();
  }
}
