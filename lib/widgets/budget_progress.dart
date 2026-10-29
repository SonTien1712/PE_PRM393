import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/budget_alert_calculator.dart';
import '../core/money_format.dart';
import '../data/models/budget.dart';
import '../data/models/budget_alert.dart';

class BudgetProgress extends StatelessWidget {
  const BudgetProgress({
    super.key,
    required this.budget,
    required this.spent,
    required this.onEdit,
    this.enabled = true,
  });
  final Budget? budget;
  final int spent;
  final VoidCallback onEdit;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final limit = budget?.limitAmount;
    final level = limit == null ? null : budgetLevel(spent, limit);
    final color = switch (level) {
      BudgetAlertLevel.exceeded => AppTheme.expense,
      BudgetAlertLevel.warning => AppTheme.warning,
      null => AppTheme.income,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ngân sách tháng',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (limit == null) ...[
              const Text(
                'Đặt hạn mức để chủ động kiểm soát chi tiêu.',
                style: TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: enabled ? onEdit : null,
                icon: const Icon(Icons.savings_outlined),
                label: const Text('Đặt ngân sách'),
              ),
            ] else ...[
              Text(
                '${formatVnd(spent)} đã chi',
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Hạn mức ${formatVnd(limit)}',
                style: const TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (spent / limit).clamp(0.0, 1.0),
                color: color,
                backgroundColor: AppTheme.line,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                semanticsLabel: 'Ngân sách đã dùng',
              ),
              const SizedBox(height: 8),
              Text(switch (level) {
                BudgetAlertLevel.exceeded => 'Đã vượt ngân sách tháng!',
                BudgetAlertLevel.warning =>
                  'Đã dùng ${(spent * 100 / limit).round()}% ngân sách',
                null => 'Còn ${formatVnd(limit - spent)}',
              }, style: TextStyle(color: color, fontSize: 13)),
              const SizedBox(height: 4),
              TextButton(
                onPressed: enabled ? onEdit : null,
                child: const Text('Điều chỉnh ngân sách'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
