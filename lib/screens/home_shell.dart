import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/provider_error_listener.dart';
import 'dashboard_screen.dart';
import 'transaction_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selected = 0;
  bool _loggingOut = false;

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    try {
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'Đăng xuất?',
        message: 'Dữ liệu của bạn đã được lưu trên thiết bị.',
        confirmLabel: 'Đăng xuất',
        destructive: false,
      );
      if (!mounted || !confirmed || auth.currentUser?.id != userId) return;
      await auth.logout();
      if (!mounted || auth.currentUser == null) return;
      final message = auth.errorMessage;
      if (message != null) {
        auth.clearError();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return ProviderErrorListener(
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SỔ THU CHI',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.8,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                'Xin chào, ${user?.displayName ?? ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Tùy chọn',
              enabled: !_loggingOut,
              onSelected: (_) => _logout(),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.logout),
                    title: Text('Đăng xuất'),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: IndexedStack(
          index: _selected,
          children: [
            DashboardScreen(onViewAll: () => setState(() => _selected = 1)),
            const TransactionListScreen(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _loggingOut
              ? null
              : () => Navigator.pushNamed(context, AppRoutes.transactionNew),
          tooltip: 'Thêm giao dịch',
          icon: const Icon(Icons.add),
          label: const Text('Thêm giao dịch'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selected,
          onDestinationSelected: (value) => setState(() => _selected = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Tổng quan',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Giao dịch',
            ),
          ],
        ),
      ),
    );
  }
}
