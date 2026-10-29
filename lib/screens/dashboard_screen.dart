import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/app_spacing.dart';
import '../core/app_theme.dart';
import '../providers/transaction_provider.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/empty_state.dart';
import '../widgets/month_overview.dart';
import '../widgets/responsive_body.dart';
import '../widgets/stale_data_banner.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onViewAll});
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) => Consumer<TransactionProvider>(
    builder: (context, provider, _) {
      final totals = provider.totals;
      final text = Theme.of(context).textTheme;
      return ResponsiveBody(
        child: RefreshIndicator(
          onRefresh: () async {
            await provider.refresh();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              96,
            ),
            children: [
              const StaleDataBanner(),
              Row(
                children: [
                  Expanded(child: Text('Tổng quan', style: text.headlineSmall)),
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
                'Một góc nhìn rõ ràng về dòng tiền của bạn.',
                style: text.bodyMedium?.copyWith(color: AppTheme.muted),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!provider.hasLoaded) ...[
                if (provider.isLoading || !provider.needsRefresh)
                  const DashboardSkeleton()
                else
                  EmptyState(
                    icon: Icons.storage_outlined,
                    message: 'Chưa tải được dữ liệu.',
                    actionLabel: 'Tải lại',
                    onAction: () => provider.refresh(),
                  ),
              ] else ...[
                if (provider.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                SummaryCard(
                  title: 'Số dư',
                  amount: totals.balance,
                  color: totals.balance >= 0
                      ? AppTheme.income
                      : AppTheme.expense,
                  icon: Icons.account_balance_wallet_outlined,
                  prominent: true,
                ),
                const SizedBox(height: AppSpacing.md),
                SummaryPair(income: totals.income, expense: totals.expense),
                const SizedBox(height: AppSpacing.lg),
                const MonthOverview(),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text('Giao dịch gần đây', style: text.titleMedium),
                    ),
                    TextButton.icon(
                      onPressed: onViewAll,
                      label: const Text('Xem tất cả'),
                      icon: const Icon(Icons.chevron_right_rounded, size: 18),
                      iconAlignment: IconAlignment.end,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (provider.all.isEmpty)
                  EmptyState(
                    message: 'Chưa có giao dịch. Nhấn + để thêm.',
                    actionLabel: 'Thêm giao dịch',
                    onAction: () =>
                        Navigator.pushNamed(context, AppRoutes.transactionNew),
                  )
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
            ],
          ),
        ),
      );
    },
  );
}
