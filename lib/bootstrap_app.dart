import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/app_theme.dart';
import 'data/app_database.dart';
import 'data/csv_export_service.dart';
import 'data/repositories/budget_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/session_storage.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'widgets/mobile_app_frame.dart';

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<AppDatabase> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<AppDatabase> _initialize() async {
    await initializeDateFormatting('vi_VN');
    return AppDatabase.open();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppDatabase>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.hasData) return buildInitializedApp(snapshot.requireData);
      final failed =
          snapshot.connectionState == ConnectionState.done && snapshot.hasError;
      return MaterialApp(
        title: 'Sổ Thu Chi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) => MobileAppFrame(child: child!),
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    failed
                        ? Icons.storage_outlined
                        : Icons.account_balance_wallet_outlined,
                    size: 56,
                    color: AppTheme.teal,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    failed
                        ? 'Không thể mở dữ liệu. Vui lòng thử lại.'
                        : 'Sổ Thu Chi',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  if (!failed)
                    const CircularProgressIndicator()
                  else
                    FilledButton.icon(
                      onPressed: () => setState(() {
                        _initialization = _initialize();
                      }),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget buildInitializedApp(AppDatabase appDb) => MultiProvider(
  providers: [
    Provider.value(value: appDb),
    Provider(create: (_) => CsvExportService()),
    Provider(create: (_) => UserRepository(appDb)),
    Provider(create: (_) => TransactionRepository(appDb)),
    Provider(create: (_) => BudgetRepository(appDb)),
    Provider(create: (_) => SessionStorage()),
    ChangeNotifierProvider(
      create: (context) => AuthProvider(context.read(), context.read()),
    ),
    ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
      create: (context) => TransactionProvider(context.read(), context.read()),
      update: (_, auth, previous) {
        previous!.setUser(auth.currentUser?.id);
        return previous;
      },
    ),
  ],
  child: const App(),
);
