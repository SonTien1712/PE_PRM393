import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';

/// Delivers read errors once, outside build, on the visible authenticated route.
class ProviderErrorListener extends StatefulWidget {
  const ProviderErrorListener({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<ProviderErrorListener> createState() => _ProviderErrorListenerState();
}

class _ProviderErrorListenerState extends State<ProviderErrorListener> {
  TransactionProvider? _provider;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<TransactionProvider>();
    if (identical(provider, _provider)) return;
    _provider?.removeListener(_onChanged);
    _provider = provider..addListener(_onChanged);
    _onChanged();
  }

  void _onChanged() {
    final provider = _provider;
    if (provider == null || provider.errorMessage == null || _scheduled) return;
    final epoch = provider.userEpoch;
    final message = provider.errorMessage;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted ||
          !widget.enabled ||
          epoch != provider.userEpoch ||
          provider.errorMessage != message ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      provider.clearError();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message!)));
    });
  }

  @override
  void dispose() {
    _provider?.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
