import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../data/models/finance_transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/provider_error_listener.dart';
import '../widgets/responsive_body.dart';
import '../widgets/transaction_details.dart';

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
          appBar: AppBar(
            toolbarHeight: MediaQuery.textScalerOf(context)
                .scale(56)
                .clamp(56.0, 112.0),
            title: const Text(
              'Chi tiết giao dịch',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (tx != null)
                IconButton(
                  tooltip: 'Sửa giao dịch',
                  onPressed: _deleting || _closing ? null : () => _edit(tx),
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
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
                : TransactionDetails(
                    tx: tx,
                    deleting: _deleting,
                    onDelete: _delete,
                  ),
          ),
        ),
      );
    },
  );
}
