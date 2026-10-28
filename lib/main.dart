import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'bootstrap_app.dart';
import 'core/platform_utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (isDesktop) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const BootstrapApp());
}
