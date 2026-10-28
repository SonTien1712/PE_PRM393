import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../core/money_format.dart';
import '../data/models/finance_transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/provider_error_listener.dart';
import '../widgets/responsive_body.dart';

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _deleting = false;
  bool _closing = false;
  bool _missingScheduled = false;

  void _scheduleMissingClose(TransactionProvider provider) {
    if (_closing ||
        _deleting ||
        _missingScheduled ||
        !provider.hasLoaded ||
        !provider.lastRefreshSucceeded ||
        provider.isLoading ||
        provider.errorMessage != null) {
      return;
    }
    _missingScheduled = true;
    final epoch = provider.userEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _missingScheduled = false;
      if (!mounted ||
          _closing ||
          _deleting ||
          epoch != provider.userEpoch ||
          !provider.hasLoaded ||
          !provider.lastRefreshSucceeded ||
          provider.isLoading ||
          provider.errorMessage != null ||
          provider.byId(widget.id) != null ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      _closing = true;
      Navigator.of(context).pop();
    });
  }

  Future<void> _edit(FinanceTransaction tx) async {
    final provider = context.read<TransactionProvider>();
    final epoch = provider.userEpoch;
    await Navigator.pushNamed(
      context,
      AppRoutes.transactionEdit,
      arguments: tx,
    );
    if (mounted && provider.userEpoch == epoch) setState(() {});
  }

  Future<void> _delete() async {
    if (_deleting || _closing) return;
    setState(() => _deleting = true);
    final provider = context.read<TransactionProvider>();
    final epoch = provider.userEpoch;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'Xóa giao dịch?',
        message:
            'Giao dịch này sẽ bị xóa khỏi sổ thu chi và không thể khôi phục.',
        confirmLabel: 'Xóa',
      );
      if (!mounted || !confirmed || provider.userEpoch != epoch) return;
      final ok = await provider.delete(widget.id);
      if (!mounted || provider.userEpoch != epoch) return;
      final message = provider.errorMessage;
      if (message != null) provider.clearError();
      if (ok) {
        _closing = true;
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Đã xóa giao dịch')),
        );
        if (message != null) {
          messenger.showSnackBar(SnackBar(content: Text(message)));
        }
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              message ?? 'Không thể xóa giao dịch. Vui lòng thử lại.',
            ),
          ),
        );
      }
    } finally {
      if (mounted && provider.userEpoch == epoch && !_closing) {
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<TransactionProvider>(
    builder: (context, provider, _) {
      final tx = provider.byId(widget.id);
      if (tx == null) _scheduleMissingClose(provider);
      return ProviderErrorListener(
        enabled: !_deleting,
        child: Scaffold(
          appBar: AppBar(title: const Text('Chi tiết giao dịch')),
          body: ResponsiveBody(
            child: tx == null
                ? Center(
                    child: provider.isLoading || _deleting
                        ? const CircularProgressIndicator()
                        : EmptyState(
                            icon: Icons.receipt_long_outlined,
                            message: 'Không tìm thấy giao dịch.',
                            actionLabel: 'Tải lại',
                            onAction: () => provider.refresh(),
                          ),
                  )
                : _buildDetails(context, tx),
          ),
        ),
      );
    },
  );

  Widget _buildDetails(BuildContext context, FinanceTransaction tx) {
    final income = tx.type == TxType.income;
    final color = income ? AppTheme.income : AppTheme.expense;
    final created = DateTime.tryParse(tx.createdAt)?.toLocal();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(
                    income
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    size: 28,
                    color: color,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  income ? 'Khoản thu' : 'Khoản chi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${income ? '+' : '−'}${formatVnd(tx.amount)}',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700, color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailField(label: 'Danh mục', value: tx.category),
                const Divider(height: 28),
                _DetailField(
                  label: 'Ngày giao dịch',
                  value: DateFormat(
                    'dd/MM/yyyy',
                    'vi_VN',
                  ).format(DateTime.parse(tx.date)),
                ),
                const Divider(height: 28),
                _DetailField(
                  label: 'Ghi chú',
                  value: tx.note?.trim().isNotEmpty == true
                      ? tx.note!
                      : 'Không có ghi chú',
                ),
                const Divider(height: 28),
                _DetailField(
                  label: 'Thời gian tạo',
                  value: created == null
                      ? '—'
                      : DateFormat('dd/MM/yyyy HH:mm', 'vi_VN').format(created),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _deleting ? null : () => _edit(tx),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Sửa giao dịch'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _deleting ? null : _delete,
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.expense),
          icon: _deleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline_rounded),
          label: Text(_deleting ? 'Đang xử lý…' : 'Xóa giao dịch'),
        ),
      ],
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 6),
      SelectableText(value, style: Theme.of(context).textTheme.bodyLarge),
    ],
  );
}
