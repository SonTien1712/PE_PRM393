import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/amount_input_formatter.dart';
import '../core/categories.dart';
import '../core/money_format.dart';
import '../core/validators.dart';
import '../data/models/finance_transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/responsive_body.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key, this.initial});

  final FinanceTransaction? initial;

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

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _type = initial?.type ?? TxType.expense;
    _category = initial?.category;
    _date = initial == null
        ? DateUtils.dateOnly(DateTime.now())
        : DateTime.parse(initial.date);
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
      lastDate: DateUtils.dateOnly(DateTime.now()),
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
      createdAt: widget.initial?.createdAt ?? DateTime.now().toIso8601String(),
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
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.message ??
                (_editing ? 'Đã cập nhật giao dịch' : 'Đã thêm giao dịch'),
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
    body: ResponsiveBody(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
                  helperText: formatVnd(parseAmountOrNull(_amount.text) ?? 0),
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                key: ValueKey('$_type:$_category'),
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categoriesFor(_type)
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                validator: (value) => validateCategory(value, _type),
                onChanged: _isSaving
                    ? null
                    : (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _dateText,
                enabled: !_isSaving,
                readOnly: true,
                onTap: _pickDate,
                validator: (_) => validateDate(_date),
                decoration: const InputDecoration(
                  labelText: 'Ngày giao dịch',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  suffixIcon: Icon(Icons.expand_more_rounded),
                ),
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
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_isSaving ? 'Đang lưu…' : 'Lưu giao dịch'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
