import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/app_spacing.dart';
import '../core/money_format.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.prominent = false,
  });

  final String title;
  final int amount;
  final Color color;
  final IconData icon;
  final bool prominent;

  @override
  Widget build(BuildContext context) => Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        prominent ? AppRadii.balance : AppRadii.card,
      ),
      side: const BorderSide(color: AppTheme.line),
    ),
    color: prominent
        ? (amount >= 0 ? AppTheme.incomeSurface : AppTheme.expenseSurface)
        : null,
    child: Padding(
      padding: EdgeInsets.all(prominent ? AppSpacing.lg : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatVnd(amount),
            style: TextStyle(
              fontSize: prominent ? 30 : 20,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (prominent) ...[
            const SizedBox(height: 12),
            const Text(
              'Toàn thời gian · Tổng thu − Tổng chi',
              style: TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
          ],
        ],
      ),
    ),
  );
}

class SummaryPair extends StatelessWidget {
  const SummaryPair({
    super.key,
    required this.income,
    required this.expense,
    this.incomeLabel = 'Tổng thu',
    this.expenseLabel = 'Tổng chi',
  });
  final int income;
  final int expense;
  final String incomeLabel;
  final String expenseLabel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cards = [
        SummaryCard(
          title: incomeLabel,
          amount: income,
          color: AppTheme.income,
          icon: Icons.south_west_rounded,
        ),
        SummaryCard(
          title: expenseLabel,
          amount: expense,
          color: AppTheme.expense,
          icon: Icons.north_east_rounded,
        ),
      ];
      final wideNumber =
          income.toString().length > 9 || expense.toString().length > 9;
      final stacked =
          box.maxWidth < 300 ||
          wideNumber ||
          MediaQuery.textScalerOf(context).scale(16) > 20;
      return stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [cards[0], const SizedBox(height: 12), cards[1]],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
              ],
            );
    },
  );
}
