import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/app_exception.dart';
import '../data/csv_export_service.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
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
  bool _exporting = false;

  Future<void> _exportCsv() async {
    if (_exporting || _loggingOut) return;
    setState(() => _exporting = true);
    final provider = context.read<TransactionProvider>();
    final exporter = context.read<CsvExportService>();
    final messenger = ScaffoldMessenger.of(context);
    final epoch = provider.userEpoch;
    bool current() =>
        mounted && epoch == provider.userEpoch && provider.userId != null;
    try {
      final csv = await provider.buildCsv();
      if (!current()) return;
      final saved = await exporter.export(csv, isCurrent: current);
      if (!current() || saved == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            exporter.desktop ? 'Đã lưu: $saved' : 'Đã mở bảng chia sẻ CSV.',
          ),
        ),
      );
    } catch (error) {
      if (current()) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              error is AppException
                  ? error.message
                  : 'Không thể xuất file. Vui lòng thử lại.',
            ),
          ),
        );
      }
    } finally {
      if (current()) setState(() => _exporting = false);
    }
  }

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
          toolbarHeight: MediaQuery.textScalerOf(context)
              .scale(56)
              .clamp(64.0, 112.0),
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
              enabled: !_loggingOut && !_exporting,
              onSelected: (value) {
                if (value == 'budget') {
                  Navigator.pushNamed(context, AppRoutes.budget);
                } else if (value == 'export') {
                  _exportCsv();
                } else {
                  _logout();
                }
              },
              itemBuilder: (_) => [
                if (_selected == 1)
                  const PopupMenuItem(
                    value: 'export',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.file_download_outlined),
                      title: Text('Xuất CSV'),
                      subtitle: Text('Toàn bộ giao dịch của bạn'),
                    ),
                  ),
                const PopupMenuItem(
                  value: 'budget',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.savings_outlined),
                    title: Text('Ngân sách'),
                  ),
                ),
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
        body: Column(
          children: [
            if (_exporting)
              const LinearProgressIndicator(semanticsLabel: 'Đang xuất CSV'),
            Expanded(
              child: IndexedStack(
                index: _selected,
                children: [
                  DashboardScreen(
                    onViewAll: () => setState(() => _selected = 1),
                  ),
                  const TransactionListScreen(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _loggingOut
              ? null
              : () => Navigator.pushNamed(context, AppRoutes.transactionNew),
          tooltip: 'Thêm giao dịch',
          child: const Icon(Icons.add),
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
