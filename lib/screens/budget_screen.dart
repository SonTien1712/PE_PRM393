import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/amount_input_formatter.dart';
import '../core/app_exception.dart';
import '../core/app_theme.dart';
import '../core/money_format.dart';
import '../core/validators.dart';
import '../providers/transaction_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/responsive_body.dart';
import '../widgets/form_footer.dart';
import '../widgets/info_banner.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _form = GlobalKey<FormState>();
  final _limit = TextEditingController();
  bool _initialized = false;
  bool _busy = false;
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<TransactionProvider>(context);
    if (!_initialized && provider.hasMonthData) {
      _limit.text = provider.monthBudget?.limitAmount.toString() ?? '';
      _initialized = true;
    }
  }

  Future<void> _submit({bool remove = false}) async {
    if (_busy || _done || (!remove && !_form.currentState!.validate())) return;
    setState(() => _busy = true);
    FocusScope.of(context).unfocus();
    final provider = context.read<TransactionProvider>();
    final epoch = provider.userEpoch;
    final month = provider.selectedMonthKey;
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (remove) {
        final confirmed = await ConfirmDialog.show(
          context,
          title: 'Xóa ngân sách?',
          message: 'Chỉ xóa hạn mức tháng này. Các giao dịch vẫn được giữ lại.',
          confirmLabel: 'Xóa',
        );
        if (!mounted ||
            !confirmed ||
            epoch != provider.userEpoch ||
            month != provider.selectedMonthKey) {
          return;
        }
        await provider.removeBudget();
      } else {
        await provider.saveBudget(int.parse(_limit.text));
      }
      if (!mounted || epoch != provider.userEpoch) return;
      final warning = provider.errorMessage;
      if (warning != null) provider.clearError();
      _done = true;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            warning ?? (remove ? 'Đã xóa ngân sách' : 'Đã lưu ngân sách'),
          ),
        ),
      );
    } catch (error) {
      if (mounted && epoch == provider.userEpoch) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              error is AppException
                  ? error.message
                  : 'Không thể lưu ngân sách. Vui lòng thử lại.',
            ),
          ),
        );
      }
    } finally {
      if (mounted && epoch == provider.userEpoch && !_done) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final disabled = _busy || provider.isSaving || !provider.hasMonthData;
    return Scaffold(
      appBar: AppBar(title: const Text('Ngân sách')),
      bottomNavigationBar: FormFooter(
        onSave: disabled ? null : () => _submit(),
        onCancel: () => Navigator.of(context).maybePop(),
        label: 'Lưu ngân sách',
        busy: _busy,
      ),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.savings_outlined, size: 48, color: AppTheme.teal),
            const SizedBox(height: 20),
            Text(
              'Chi tiêu có kế hoạch',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tháng ${DateFormat('MM/yyyy').format(provider.selectedMonth)}',
              style: const TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: 24),
            if (!provider.hasMonthData) ...[
              const Text('Cần tải thống kê tháng trước khi đặt ngân sách.'),
              TextButton(
                onPressed: provider.isLoading ? null : () => provider.refresh(),
                child: const Text('Thử tải lại'),
              ),
            ],
            Form(
              key: _form,
              child: TextFormField(
                controller: _limit,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                enabled: !disabled,
                validator: validateBudgetLimit,
                keyboardType: TextInputType.number,
                inputFormatters: [amountInputFormatter],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Hạn mức chi tiêu (₫)',
                  helperText:
                      '= ${formatVnd(parseAmountOrNull(_limit.text) ?? 0)}',
                  helperMaxLines: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const InfoBanner(
              message: 'Ứng dụng sẽ nhắc khi khoản chi làm ngân sách đạt 80% hoặc vượt hạn mức.',
              icon: Icons.notifications_active_outlined,
              foreground: AppTheme.warning,
              background: Color(0xFFFFF8E7),
            ),
            const SizedBox(height: 28),
            if (provider.monthBudget != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: disabled ? null : () => _submit(remove: true),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Xóa ngân sách'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.expense,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
