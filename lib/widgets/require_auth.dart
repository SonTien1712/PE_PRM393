import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../providers/auth_provider.dart';

class RequireAuth extends StatefulWidget {
  const RequireAuth({super.key, required this.child});

  final Widget child;

  @override
  State<RequireAuth> createState() => _RequireAuthState();
}

class _RequireAuthState extends State<RequireAuth> {
  bool _redirectScheduled = false;

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthProvider>().currentUser != null) return widget.child;
    if (!_redirectScheduled) {
      _redirectScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _redirectScheduled = false;
        if (context.read<AuthProvider>().currentUser == null &&
            ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
        }
      });
    }
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
