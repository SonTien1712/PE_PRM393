class SummaryTotals {
  const SummaryTotals({required this.income, required this.expense});

  final int income;
  final int expense;

  int get balance => income - expense;

  factory SummaryTotals.fromMap(Map<String, Object?> map) => SummaryTotals(
    income: (map['income'] as num?)?.toInt() ?? 0,
    expense: (map['expense'] as num?)?.toInt() ?? 0,
  );

  Map<String, Object?> toMap() => {'income': income, 'expense': expense};
}
