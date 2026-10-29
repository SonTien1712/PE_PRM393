import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'data/models/finance_transaction.dart';
import 'screens/home_shell.dart';
import 'screens/budget_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/transaction_detail_screen.dart';
import 'screens/transaction_form_screen.dart';
import 'widgets/require_auth.dart';
import 'widgets/mobile_app_frame.dart';

class App extends StatelessWidget {
  const App({super.key, this.now});
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) => MaterialApp(
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
    onGenerateRoute: _route,
  );

  Route<void> _route(RouteSettings settings) {
    final Widget screen;
    var protected = false;
    switch (settings.name) {
      case AppRoutes.splash:
        screen = const SplashScreen();
      case AppRoutes.login:
        screen = const LoginScreen();
      case AppRoutes.register:
        screen = const RegisterScreen();
      case AppRoutes.home:
        protected = true;
        screen = const HomeShell();
      case AppRoutes.budget:
        protected = true;
        screen = const BudgetScreen();
      case AppRoutes.transactionNew:
        protected = true;
        screen = TransactionFormScreen(now: now);
      case AppRoutes.transactionEdit:
        protected = true;
        final argument = settings.arguments;
        screen = argument is FinanceTransaction
            ? TransactionFormScreen(initial: argument, now: now)
            : const _UnknownScreen();
      case AppRoutes.transactionDetail:
        protected = true;
        final argument = settings.arguments;
        screen = argument is int
            ? TransactionDetailScreen(id: argument)
            : const _UnknownScreen();
      default:
        screen = const _UnknownScreen();
    }
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => protected ? RequireAuth(child: screen) : screen,
    );
  }
}

class _UnknownScreen extends StatelessWidget {
  const _UnknownScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Không tìm thấy trang')),
    body: Center(
      child: FilledButton.icon(
        onPressed: () =>
            Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRoutes.splash, (_) => false),
        icon: const Icon(Icons.home_outlined),
        label: const Text('Về trang bắt đầu'),
      ),
    ),
  );
}
