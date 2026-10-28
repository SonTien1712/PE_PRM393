import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/app_exception.dart';
import '../../core/constants.dart';

Future<T> runDatabaseOperation<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DatabaseException catch (error, stackTrace) {
    debugPrint('Database operation failed: $error\n$stackTrace');
    throw const AppException(databaseErrorMessage);
  }
}
