import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/category_appearance.dart';
import '../core/money_format.dart';
import '../data/models/category_total.dart';

class CategoryBreakdown extends StatelessWidget {
  const CategoryBreakdown({
    super.key,
    required this.rows,
    required this.expense,
  });
  final List<CategoryTotal> rows;
  final int expense;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Chi tiêu theo danh mục',
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      if (rows.isEmpty || expense == 0)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Chưa có khoản chi trong tháng này.',
            style: TextStyle(color: AppTheme.muted),
          ),
        )
      else
        ...rows.map((row) {
          final ratio = (row.total / expense).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      categoryIcon(row.category),
                      size: 18,
                      color: AppTheme.muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(row.category)),
                    Text(
                      '${(ratio * 100).round()}%',
                      style: const TextStyle(color: AppTheme.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  formatVnd(row.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.expense,
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label:
                      '${row.category}: ${(ratio * 100).round()} phần trăm chi tiêu',
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(4),
                    color: AppTheme.expense,
                    backgroundColor: AppTheme.expenseSurface,
                  ),
                ),
              ],
            ),
          );
        }),
    ],
  );
}
