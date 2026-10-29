import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_exception.dart';
import '../core/platform_utils.dart';

class CsvExportService {
  CsvExportService({
    bool? desktop,
    this.directory,
    Future<void> Function(String)? shareFile,
    Future<void> Function(File, String)? writeFile,
    DateTime Function()? now,
  }) : desktop = desktop ?? isDesktop,
       _shareFile = shareFile ?? _share,
       _writeFile = writeFile ?? _write,
       _now = now ?? DateTime.now;

  final bool desktop;
  final Future<Directory> Function()? directory;
  final Future<void> Function(String) _shareFile;
  final Future<void> Function(File, String) _writeFile;
  final DateTime Function() _now;

  static Future<void> _write(File file, String csv) async {
    await file.writeAsString(csv, flush: true);
  }

  static Future<void> _share(String filePath) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'text/csv')],
        title: 'Xuất sổ thu chi',
      ),
    );
  }

  Future<Directory> _defaultDirectory() async {
    if (!desktop) return getTemporaryDirectory();
    return await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
  }

  /// A null result means this export was abandoned after a session change.
  Future<String?> export(
    String csv, {
    required bool Function() isCurrent,
  }) async {
    File? output;
    try {
      if (!isCurrent()) return null;
      final directory = await (this.directory?.call() ?? _defaultDirectory());
      if (!isCurrent()) return null;
      await directory.create(recursive: true);
      if (!isCurrent()) return null;
      final stem =
          'finance_export_${DateFormat('yyyyMMdd_HHmmss').format(_now())}';
      var candidate = File(path.join(directory.path, '$stem.csv'));
      var suffix = 0;
      while (await candidate.exists()) {
        if (!isCurrent()) return null;
        candidate = File(path.join(directory.path, '${stem}_${++suffix}.csv'));
      }
      if (!isCurrent()) return null;
      output = candidate;
      await _writeFile(output, csv);
      if (!isCurrent()) {
        await _discard(output);
        return null;
      }
      if (!desktop) {
        // Do not invoke a share sheet with another session's pending data.
        await _shareFile(output.path);
        if (!isCurrent()) {
          await _discard(output);
          return null;
        }
      }
      return output.path;
    } catch (error, stack) {
      debugPrint('CSV export failed: $error\n$stack');
      if (output != null) await _discard(output);
      if (!isCurrent()) return null;
      throw const AppException('Không thể xuất file. Vui lòng thử lại.');
    }
  }

  Future<void> _discard(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (error) {
      debugPrint('Could not remove abandoned export: $error');
    }
  }
}
