import '../data/models/budget_alert.dart';

BudgetAlertLevel? budgetLevel(int spent, int limit) {
  if (limit <= 0) return null;
  if (spent > limit) return BudgetAlertLevel.exceeded;
  if (spent * 100 >= limit * 80) return BudgetAlertLevel.warning;
  return null;
}

BudgetAlert? calculateBudgetAlert({
  required int beforeSpent,
  required int afterSpent,
  required int limit,
}) {
  final before = budgetLevel(beforeSpent, limit);
  final after = budgetLevel(afterSpent, limit);
  int rank(BudgetAlertLevel? level) => level == null ? 0 : level.index + 1;
  if (after == null || rank(after) <= rank(before)) return null;
  return BudgetAlert(level: after, spent: afterSpent, limit: limit);
}
