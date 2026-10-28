import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../providers/transaction_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bar.dart';
import '../widgets/responsive_body.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/stale_data_banner.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  TransactionProvider? _provider;
  int? _epoch;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<TransactionProvider>();
    if (identical(provider, _provider)) return;
    _provider?.removeListener(_syncSearch);
    _provider = provider..addListener(_syncSearch);
    _epoch = provider.userEpoch;
    _search.text = provider.searchQuery;
  }

  void _syncSearch() {
    final provider = _provider!;
    if (provider.userEpoch != _epoch) {
      _debounce?.cancel();
      _epoch = provider.userEpoch;
    }
    if (!(_debounce?.isActive ?? false) &&
        _search.text != provider.searchQuery) {
      _search.text = provider.searchQuery;
    }
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    final provider = _provider!;
    final epoch = provider.userEpoch;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted && provider.userEpoch == epoch) provider.setSearch(query);
    });
  }

  void _clearFilters() {
    _debounce?.cancel();
    _search.clear();
    _provider!.clearFilters();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _provider?.removeListener(_syncSearch);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer<TransactionProvider>(
    builder: (context, provider, _) {
      final rows = provider.visible;
      return ResponsiveBody(
        child: RefreshIndicator(
          onRefresh: () async {
            await provider.refresh();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: StaleDataBanner()),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      TextField(
                        controller: _search,
                        onChanged: _onSearch,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (query) {
                          _debounce?.cancel();
                          provider.setSearch(query);
                        },
                        onTapOutside: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        decoration: InputDecoration(
                          hintText: 'Tìm ghi chú hoặc danh mục',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: IconButton(
                            tooltip: 'Xóa tìm kiếm',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _debounce?.cancel();
                              _search.clear();
                              provider.setSearch('');
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilterBar(provider: provider, onClear: _clearFilters),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${rows.length} giao dịch · ${FilterBar.sortLabels[provider.sort]}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Tải lại',
                            onPressed: provider.isLoading
                                ? null
                                : () => provider.refresh(),
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (provider.isLoading)
                const SliverToBoxAdapter(child: LinearProgressIndicator()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                sliver: SliverList.builder(
                  itemCount: rows.isEmpty ? 1 : rows.length,
                  itemBuilder: (context, index) {
                    if (rows.isEmpty) {
                      if (!provider.hasLoaded && provider.isLoading) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (!provider.hasLoaded) {
                        return EmptyState(
                          icon: Icons.cloud_off_outlined,
                          message: 'Chưa tải được dữ liệu.',
                          actionLabel: 'Tải lại',
                          onAction: () => provider.refresh(),
                        );
                      }
                      if (provider.all.isEmpty) {
                        return const EmptyState(
                          message: 'Chưa có giao dịch. Nhấn + để thêm.',
                        );
                      }
                      return EmptyState(
                        icon: Icons.search_off_rounded,
                        message: 'Không tìm thấy giao dịch phù hợp.',
                        actionLabel: 'Xóa bộ lọc',
                        onAction: _clearFilters,
                      );
                    }
                    final tx = rows[index];
                    return TransactionTile(
                      tx: tx,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.transactionDetail,
                        arguments: tx.id,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
