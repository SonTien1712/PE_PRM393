import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/app_routes.dart';
import '../providers/transaction_provider.dart';
import 'category_breakdown.dart';
import 'month_selector.dart';
import 'summary_card.dart';
import 'budget_progress.dart';

class MonthOverview extends StatelessWidget {
  const MonthOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Theo tháng',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        MonthSelector(
          month: provider.selectedMonth,
          canGoNext: provider.canGoNextMonth,
          enabled: !provider.isSaving,
          onChanged: provider.changeMonth,
        ),
        const SizedBox(height: 12),
        if (!provider.hasMonthData)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: provider.isMonthLoading
                  ? const Center(child: CircularProgressIndicator())
                  : const Text(
                      'Chưa tải được thống kê tháng. Hãy thử tải lại.',
                    ),
            ),
          )
        else ...[
          if (provider.isMonthLoading) const LinearProgressIndicator(),
          SummaryPair(
            income: provider.monthTotals.income,
            expense: provider.monthTotals.expense,
            incomeLabel: 'Thu nhập',
            expenseLabel: 'Chi tiêu',
          ),
          const SizedBox(height: 12),
          BudgetProgress(
            budget: provider.monthBudget,
            spent: provider.monthTotals.expense,
            enabled: !provider.isSaving,
            onEdit: () => Navigator.pushNamed(context, AppRoutes.budget),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: CategoryBreakdown(
                rows: provider.monthBreakdown,
                expense: provider.monthTotals.expense,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'Chỉ thống kê trong tháng đã chọn. Tổng ở trên luôn là toàn thời gian.',
          style: TextStyle(fontSize: 12, color: AppTheme.muted),
        ),
      ],
    );
  }
}
