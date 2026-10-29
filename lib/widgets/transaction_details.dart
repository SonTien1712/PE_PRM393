import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_spacing.dart';
import '../core/app_theme.dart';
import '../core/category_appearance.dart';
import '../core/money_format.dart';
import '../data/models/finance_transaction.dart';

class TransactionDetails extends StatelessWidget {
  const TransactionDetails({
    super.key,
    required this.tx,
    required this.deleting,
    required this.onDelete,
  });
  final FinanceTransaction tx;
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final income = tx.type == TxType.income;
    final color = income ? AppTheme.income : AppTheme.expense;
    final date = DateFormat(
      'dd/MM/yyyy',
      'vi_VN',
    ).format(DateTime.parse(tx.date));
    final created = DateTime.tryParse(tx.createdAt)?.toLocal();
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: categorySurface(tx.category, tx.type),
                    borderRadius: BorderRadius.circular(AppRadii.balance),
                  ),
                  child: Icon(
                    categoryIcon(tx.category),
                    size: 32,
                    color: color,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  tx.category,
                  textAlign: TextAlign.center,
                  style: text.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${income ? '+' : '−'}${formatVnd(tx.amount)}',
                  textAlign: TextAlign.center,
                  style: text.headlineLarge?.copyWith(color: color),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  date,
                  style: text.bodyMedium?.copyWith(color: AppTheme.muted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailField(
                  label: 'Loại giao dịch',
                  value: income ? 'Khoản thu' : 'Khoản chi',
                ),
                const Divider(height: AppSpacing.lg),
                _DetailField(label: 'Danh mục', value: tx.category),
                const Divider(height: AppSpacing.lg),
                _DetailField(label: 'Ngày giao dịch', value: date),
                const Divider(height: AppSpacing.lg),
                _DetailField(
                  label: 'Ghi chú',
                  value: tx.note?.trim().isNotEmpty == true
                      ? tx.note!
                      : 'Không có ghi chú',
                ),
                const Divider(height: AppSpacing.lg),
                _DetailField(
                  label: 'Thời gian tạo',
                  secondary: true,
                  value: created == null
                      ? '—'
                      : DateFormat('dd/MM/yyyy HH:mm', 'vi_VN').format(created),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: OutlinedButton.icon(
              onPressed: deleting ? null : onDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.expense,
              ),
              icon: deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              label: Text(deleting ? 'Đang xử lý…' : 'Xóa giao dịch'),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.value,
    this.secondary = false,
  });
  final String label;
  final String value;
  final bool secondary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final text = Theme.of(context).textTheme;
      final horizontal =
          box.maxWidth >= 340 &&
          value.length <= 36 &&
          MediaQuery.textScalerOf(context).scale(16) <= 20;
      final labelWidget = Text(label, style: text.bodySmall);
      final valueWidget = SelectableText(
        value,
        textAlign: horizontal ? TextAlign.end : TextAlign.start,
        style: secondary ? text.bodySmall : text.bodyLarge,
      );
      return horizontal
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 112, child: labelWidget),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: valueWidget),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                const SizedBox(height: AppSpacing.xs),
                valueWidget,
              ],
            );
    },
  );
}
