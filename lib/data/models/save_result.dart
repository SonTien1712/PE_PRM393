import 'budget_alert.dart';

class SaveResult {
  const SaveResult({required this.ok, this.alert, this.message});

  final bool ok;
  final BudgetAlert? alert;
  final String? message;
}
