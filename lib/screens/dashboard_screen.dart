import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../providers/transaction_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/responsive_body.dart';
import '../widgets/summary_card.dart';
import '../widgets/stale_data_banner.dart';
import '../widgets/transaction_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) => Consumer<TransactionProvider>(
    builder: (context, provider, _) {
      final totals = provider.totals;
      return ResponsiveBody(
        child: RefreshIndicator(
          onRefresh: () async {
            await provider.refresh();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              const StaleDataBanner(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tài chính của bạn',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tải lại',
                    onPressed: provider.isLoading
                        ? null
                        : () => provider.refresh(),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              Text(
                'Tổng thu chi từ trước đến nay',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      title: 'Tổng thu',
                      amount: totals.income,
                      color: AppTheme.income,
                      icon: Icons.south_west_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      title: 'Tổng chi',
                      amount: totals.expense,
                      color: AppTheme.expense,
                      icon: Icons.north_east_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SummaryCard(
                title: 'Số dư',
                amount: totals.balance,
                color: totals.balance >= 0 ? AppTheme.income : AppTheme.expense,
                icon: Icons.account_balance_wallet_outlined,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Giao dịch gần đây',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!provider.hasLoaded && provider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!provider.hasLoaded)
                EmptyState(
                  icon: Icons.cloud_off_outlined,
                  message: 'Chưa tải được dữ liệu.',
                  actionLabel: 'Tải lại',
                  onAction: () => provider.refresh(),
                )
              else if (provider.all.isEmpty)
                const EmptyState(message: 'Chưa có giao dịch. Nhấn + để thêm.')
              else
                ...provider.all
                    .take(5)
                    .map(
                      (tx) => TransactionTile(
                        tx: tx,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.transactionDetail,
                          arguments: tx.id,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      );
    },
  );
}
