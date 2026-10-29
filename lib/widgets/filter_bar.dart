import 'package:flutter/material.dart';

import '../core/app_spacing.dart';
import '../core/app_theme.dart';
import '../data/models/finance_transaction.dart';
import '../providers/transaction_provider.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key, required this.provider, required this.onClear});
  final TransactionProvider provider;
  final VoidCallback onClear;
  static const sortLabels = {
    SortOption.newest: 'Mới nhất',
    SortOption.oldest: 'Cũ nhất',
    SortOption.amountDesc: 'Tiền giảm dần',
    SortOption.amountAsc: 'Tiền tăng dần',
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final entry in <TxType?, String>{
            null: 'Tất cả',
            TxType.income: 'Thu',
            TxType.expense: 'Chi',
          }.entries)
            ChoiceChip(
              label: Text(entry.value),
              selected: provider.typeFilter == entry.key,
              avatar: entry.key == null
                  ? null
                  : Icon(
                      entry.key == TxType.income
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      size: 16,
                      color: entry.key == TxType.income
                          ? AppTheme.income
                          : AppTheme.expense,
                    ),
              onSelected: (_) => provider.setTypeFilter(entry.key),
            ),
          if (provider.hasActiveFilters)
            TextButton(onPressed: onClear, child: const Text('Xóa bộ lọc')),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      LayoutBuilder(
        builder: (context, box) {
          final category = DropdownButtonFormField<String>(
            key: ValueKey(
              '${provider.userEpoch}:${provider.typeFilter}:${provider.categoryFilter}',
            ),
            initialValue: provider.categoryFilter ?? '',
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Danh mục',
              isDense: true,
            ),
            selectedItemBuilder: (_) => [
              for (final name in [
                'Tất cả danh mục',
                ...provider.categoryOptions,
              ])
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
            items: [
              const DropdownMenuItem(value: '', child: Text('Tất cả danh mục')),
              ...provider.categoryOptions.map(
                (name) => DropdownMenuItem(value: name, child: Text(name)),
              ),
            ],
            onChanged: (value) =>
                provider.setCategoryFilter(value == '' ? null : value),
          );
          final sort = DropdownButtonFormField<SortOption>(
            key: ValueKey('sort:${provider.userEpoch}:${provider.sort}'),
            initialValue: provider.sort,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Sắp xếp',
              isDense: true,
            ),
            selectedItemBuilder: (_) => [
              for (final label in sortLabels.values)
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
            items: [
              for (final entry in sortLabels.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (value) {
              if (value != null) provider.setSort(value);
            },
          );
          final stack =
              box.maxWidth < 340 ||
              MediaQuery.textScalerOf(context).scale(16) > 20;
          return stack
              ? Column(
                  children: [
                    category,
                    const SizedBox(height: AppSpacing.md),
                    sort,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: category),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: sort),
                  ],
                );
        },
      ),
    ],
  );
}

class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({
    super.key,
    required this.provider,
    required this.onClearSearch,
  });
  final TransactionProvider provider;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.xs,
    children: [
      if (provider.searchQuery.trim().isNotEmpty)
        InputChip(
          label: Text(
            'Tìm: ${provider.searchQuery.trim()}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onDeleted: onClearSearch,
          deleteButtonTooltipMessage: 'Bỏ tìm kiếm',
        ),
      if (provider.typeFilter != null)
        InputChip(
          label: Text(
            provider.typeFilter == TxType.income ? 'Khoản thu' : 'Khoản chi',
          ),
          onDeleted: () => provider.setTypeFilter(null),
          deleteButtonTooltipMessage: 'Bỏ lọc loại',
        ),
      if (provider.categoryFilter != null)
        InputChip(
          label: Text(provider.categoryFilter!),
          onDeleted: () => provider.setCategoryFilter(null),
          deleteButtonTooltipMessage: 'Bỏ lọc danh mục',
        ),
    ],
  );
}
