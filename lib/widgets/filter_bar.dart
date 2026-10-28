import 'package:flutter/material.dart';

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
        spacing: 8,
        runSpacing: 4,
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
              onSelected: (_) => provider.setTypeFilter(entry.key),
            ),
          if (provider.hasActiveFilters)
            TextButton(onPressed: onClear, child: const Text('Xóa bộ lọc')),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              key: ValueKey(
                '${provider.userEpoch}:${provider.typeFilter}:${provider.categoryFilter}',
              ),
              initialValue: provider.categoryFilter ?? '',
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Danh mục',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Tất cả danh mục'),
                ),
                ...provider.categoryOptions.map(
                  (category) =>
                      DropdownMenuItem(value: category, child: Text(category)),
                ),
              ],
              onChanged: (value) =>
                  provider.setCategoryFilter(value == '' ? null : value),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<SortOption>(
            tooltip: 'Sắp xếp: ${sortLabels[provider.sort]}',
            initialValue: provider.sort,
            onSelected: provider.setSort,
            icon: const Icon(Icons.sort_rounded),
            itemBuilder: (_) => sortLabels.entries
                .map(
                  (entry) => CheckedPopupMenuItem(
                    value: entry.key,
                    checked: provider.sort == entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ],
  );
}
