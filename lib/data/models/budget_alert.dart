enum BudgetAlertLevel { warning, exceeded }

class BudgetAlert {
  const BudgetAlert({
    required this.level,
    required this.spent,
    required this.limit,
  });

  final BudgetAlertLevel level;
  final int spent;
  final int limit;
}
