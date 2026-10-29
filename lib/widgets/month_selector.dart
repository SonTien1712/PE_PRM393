import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.month,
    required this.canGoNext,
    required this.onChanged,
    this.enabled = true,
  });
  final DateTime month;
  final bool canGoNext;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: 'Tháng trước',
        onPressed: enabled && month.isAfter(DateTime(2000))
            ? () => onChanged(-1)
            : null,
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      Expanded(
        child: Text(
          'Tháng ${DateFormat('MM/yyyy').format(month)}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      IconButton(
        tooltip: 'Tháng sau',
        onPressed: enabled && canGoNext ? () => onChanged(1) : null,
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ],
  );
}
