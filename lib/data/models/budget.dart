class Budget {
  const Budget({
    this.id,
    required this.userId,
    required this.month,
    required this.limitAmount,
  });

  final int? id;
  final int userId;
  final String month;
  final int limitAmount;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'month': month,
    'limit_amount': limitAmount,
  };

  factory Budget.fromMap(Map<String, Object?> map) => Budget(
    id: map['id'] as int?,
    userId: map['user_id'] as int,
    month: map['month'] as String,
    limitAmount: map['limit_amount'] as int,
  );
}
