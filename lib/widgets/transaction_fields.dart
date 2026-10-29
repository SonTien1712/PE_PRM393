import 'package:flutter/material.dart';

import '../core/app_spacing.dart';
import '../core/categories.dart';
import '../core/category_appearance.dart';
import '../core/validators.dart';
import '../data/models/finance_transaction.dart';

class AdaptiveTransactionFields extends StatelessWidget {
  const AdaptiveTransactionFields({
    super.key,
    required this.type,
    required this.category,
    required this.date,
    required this.dateText,
    required this.onCategoryChanged,
    required this.onPickDate,
    required this.enabled,
    this.today,
  });

  final TxType type;
  final String? category;
  final DateTime date;
  final TextEditingController dateText;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onPickDate;
  final bool enabled;
  final DateTime? today;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wide =
          box.maxWidth >= 420 &&
          MediaQuery.textScalerOf(context).scale(16) <= 20;
      final categoryField = DropdownButtonFormField<String>(
        key: ValueKey('$type:$category'),
        initialValue: category,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Danh mục',
          prefixIcon: Icon(categoryIcon(category ?? '')),
          prefixIconConstraints: wide
              ? const BoxConstraints(minWidth: 40, minHeight: 48)
              : null,
        ),
        items: categoriesFor(type)
            .map(
              (value) => DropdownMenuItem(
                value: value,
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        validator: (value) => validateCategory(value, type),
        onChanged: enabled ? onCategoryChanged : null,
      );
      final dateField = TextFormField(
        controller: dateText,
        enabled: enabled,
        readOnly: true,
        onTap: onPickDate,
        validator: (_) => validateDate(date, today: today),
        decoration: InputDecoration(
          labelText: 'Ngày giao dịch',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          prefixIconConstraints: wide
              ? const BoxConstraints(minWidth: 40, minHeight: 48)
              : null,
          suffixIcon: wide ? null : const Icon(Icons.expand_more_rounded),
        ),
      );
      return wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: categoryField),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: dateField),
              ],
            )
          : Column(
              children: [
                categoryField,
                const SizedBox(height: AppSpacing.lg),
                dateField,
              ],
            );
    },
  );
}
