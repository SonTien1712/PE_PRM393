import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';

class StaleDataBanner extends StatelessWidget {
  const StaleDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    if (!provider.needsRefresh) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Dữ liệu có thể chưa cập nhật.'),
              TextButton.icon(
                onPressed: provider.isLoading ? null : () => provider.refresh(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Thử tải lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
