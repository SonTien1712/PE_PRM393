import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/amount_input_formatter.dart';
import '../core/app_theme.dart';
import '../core/app_spacing.dart';
import '../core/money_format.dart';
import '../core/validators.dart';
import '../data/models/finance_transaction.dart';
import '../data/models/budget_alert.dart';
import '../providers/transaction_provider.dart';
import '../widgets/responsive_body.dart';
import '../widgets/form_footer.dart';
import '../widgets/transaction_fields.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key, this.initial, this.now});

  final FinanceTransaction? initial;
  final DateTime Function()? now;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _note;
  final _dateText = TextEditingController();
  late TxType _type;
  String? _category;
  late DateTime _date;
  bool _isSaving = false;
  bool _didSave = false;

  bool get _editing => widget.initial != null;
  DateTime _now() => (widget.now ?? DateTime.now)();
  DateTime get _today => DateUtils.dateOnly(_now());

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _type = initial?.type ?? TxType.expense;
    _category = initial?.category;
    _date = initial == null ? _today : DateTime.parse(initial.date);
    _amount = TextEditingController(text: initial?.amount.toString() ?? '');
    _note = TextEditingController(text: initial?.note ?? '');
    _updateDateText();
  }

  void _updateDateText() {
    _dateText.text = DateFormat('dd/MM/yyyy', 'vi_VN').format(_date);
  }

  Future<void> _pickDate() async {
    if (_isSaving) return;
    final provider = context.read<TransactionProvider>();
    final epoch = provider.userEpoch;
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: _today,
      locale: const Locale('vi'),
    );
    if (!mounted || epoch != provider.userEpoch || date == null) return;
    setState(() {
      _date = date;
      _updateDateText();
    });
  }

  Future<void> _save() async {
    if (_isSaving || _didSave || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    FocusScope.of(context).unfocus();
    final provider = context.read<TransactionProvider>();
    final epoch = provider.userEpoch;
    final messenger = ScaffoldMessenger.of(context);
    final tx = FinanceTransaction(
      id: widget.initial?.id,
      userId: 0, // Authenticated ownership is assigned by the provider.
      type: _type,
      amount: int.parse(_amount.text),
      category: _category!,
      date: DateFormat('yyyy-MM-dd').format(_date),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      createdAt: widget.initial?.createdAt ?? _now().toIso8601String(),
    );
    try {
      final result = _editing
          ? await provider.update(tx)
          : await provider.add(tx);
      if (!mounted || epoch != provider.userEpoch) return;
      if (result.message != null && provider.errorMessage == result.message) {
        provider.clearError();
      }
      if (!result.ok) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? 'Không thể lưu giao dịch. Vui lòng thử lại.',
            ),
          ),
        );
        return;
      }
      _didSave = true;
      Navigator.of(context).pop();
      final alert = result.alert;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: alert == null
              ? null
              : (alert.level == BudgetAlertLevel.exceeded
                    ? AppTheme.expense
                    : AppTheme.warning),
          content: Text(
            result.message ??
                (alert == null
                    ? (_editing ? 'Đã cập nhật giao dịch' : 'Đã thêm giao dịch')
                    : alert.level == BudgetAlertLevel.exceeded
                    ? 'Đã vượt ngân sách tháng!'
                    : 'Sắp vượt ngân sách tháng (${(alert.spent * 100 / alert.limit).round()}%)'),
          ),
        ),
      );
    } finally {
      if (mounted && provider.userEpoch == epoch && !_didSave) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _dateText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_editing ? 'Sửa giao dịch' : 'Thêm giao dịch')),
    bottomNavigationBar: FormFooter(
      onSave: _save,
      onCancel: () => Navigator.of(context).maybePop(),
      label: 'Lưu giao dịch',
      busy: _isSaving,
    ),
    body: ResponsiveBody(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ghi lại khoản thu chi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Các khoản tiền được tính bằng đồng Việt Nam.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SegmentedButton<TxType>(
                style: ButtonStyle(
                  animationDuration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 150),
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? (_type == TxType.income
                              ? AppTheme.incomeSurface
                              : AppTheme.expenseSurface)
                        : AppTheme.surfaceCard,
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? (_type == TxType.income
                              ? AppTheme.income
                              : AppTheme.expense)
                        : AppTheme.muted,
                  ),
                ),
                segments: const [
                  ButtonSegment(
                    value: TxType.income,
                    icon: Icon(Icons.south_west_rounded),
                    label: Text('Thu'),
                  ),
                  ButtonSegment(
                    value: TxType.expense,
                    icon: Icon(Icons.north_east_rounded),
                    label: Text('Chi'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: _isSaving
                    ? null
                    : (selection) => setState(() {
                        _type = selection.first;
                        _category = null;
                      }),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amount,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                enabled: !_isSaving,
                keyboardType: TextInputType.number,
                inputFormatters: [amountInputFormatter],
                textInputAction: TextInputAction.next,
                validator: validateAmount,
                onChanged: (_) => setState(() {}),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: InputDecoration(
                  labelText: 'Số tiền (₫)',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  helperText:
                      '= ${formatVnd(parseAmountOrNull(_amount.text) ?? 0)}',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 20),
              AdaptiveTransactionFields(
                today: _today,
                type: _type,
                category: _category,
                date: _date,
                dateText: _dateText,
                enabled: !_isSaving,
                onPickDate: _pickDate,
                onCategoryChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _note,
                enabled: !_isSaving,
                minLines: 3,
                maxLines: 5,
                maxLength: 200,
                validator: validateNote,
                textCapitalization: TextCapitalization.sentences,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (không bắt buộc)',
                  alignLabelWithHint: true,
                  hintText: 'Thêm một vài chi tiết…',
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}
