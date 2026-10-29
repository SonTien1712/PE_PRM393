import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../core/category_appearance.dart';
import '../core/money_format.dart';
import '../data/models/finance_transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.tx, required this.onTap});
  final FinanceTransaction tx;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final income = tx.type == TxType.income;
    final color = income ? AppTheme.income : AppTheme.expense;
    final amount = '${income ? '+' : '−'}${formatVnd(tx.amount)}';
    final date = DateFormat(
      'dd/MM/yyyy',
      'vi_VN',
    ).format(DateTime.parse(tx.date));
    final note = tx.note?.trim();
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tx.category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          note?.isNotEmpty == true
              ? note!
              : (income ? 'Khoản thu' : 'Khoản chi'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppTheme.muted),
        ),
      ],
    );
    final icon = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: categorySurface(tx.category, tx.type),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(categoryIcon(tx.category), color: color, size: 24),
    );
    return Card(
      elevation: 1,
      shadowColor: AppTheme.ink.withValues(alpha: .08),
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        hoverColor: AppTheme.teal.withValues(alpha: .08),
        splashColor: AppTheme.teal.withValues(alpha: .08),
        focusColor: AppTheme.teal.withValues(alpha: .12),
        hoverDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 150),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, box) {
              final stacked =
                  amount.length > 15 ||
                  box.maxWidth < 290 ||
                  MediaQuery.textScalerOf(context).scale(16) > 20;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      icon,
                      const SizedBox(width: 12),
                      Expanded(child: details),
                      if (!stacked) ...[
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              amount,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (stacked) ...[
                    const SizedBox(height: 12),
                    Text(
                      amount,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
