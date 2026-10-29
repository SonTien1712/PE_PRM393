import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// A Scaffold bottom bar; keeps actions above the keyboard and SnackBars.
class FormFooter extends StatelessWidget {
  const FormFooter({
    super.key,
    required this.onSave,
    required this.onCancel,
    required this.label,
    this.busy = false,
  });
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final String label;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final save = FilledButton.icon(
      onPressed: busy ? null : onSave,
      icon: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check_rounded),
      label: Text(busy ? 'Đang lưu…' : label),
    );
    final cancel = TextButton(
      onPressed: busy ? null : onCancel,
      child: const Text('Hủy'),
    );
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.line)),
        ),
        child: SafeArea(
          top: false,
          child: Align(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: largeText
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [save, cancel],
                      )
                    : Row(
                        children: [
                          cancel,
                          const SizedBox(width: 12),
                          Expanded(child: save),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
