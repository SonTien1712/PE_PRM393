import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  Future<void> _restore() async {
    final restored = await context.read<AuthProvider>().restoreSession();
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacementNamed(restored ? AppRoutes.home : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text('Sổ thu chi', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Đang mở sổ tài chính của bạn…'),
          const SizedBox(height: 28),
          const CircularProgressIndicator(),
        ],
      ),
    ),
  );
}
