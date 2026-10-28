enum TxType { income, expense }

const _unchanged = Object();

class FinanceTransaction {
  const FinanceTransaction({
    this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    required this.createdAt,
  });

  final int? id;
  final int userId;
  final TxType type;
  final int amount;
  final String category;
  final String date;
  final String? note;
  final String createdAt;

  FinanceTransaction copyWith({
    int? id,
    int? userId,
    TxType? type,
    int? amount,
    String? category,
    String? date,
    Object? note = _unchanged,
    String? createdAt,
  }) => FinanceTransaction(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    date: date ?? this.date,
    note: identical(note, _unchanged) ? this.note : note as String?,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'type': type.name,
    'amount': amount,
    'category': category,
    'date': date,
    'note': note,
    'created_at': createdAt,
  };

  factory FinanceTransaction.fromMap(Map<String, Object?> map) =>
      FinanceTransaction(
        id: map['id'] as int?,
        userId: map['user_id'] as int,
        type: TxType.values.byName(map['type'] as String),
        amount: map['amount'] as int,
        category: map['category'] as String,
        date: map['date'] as String,
        note: map['note'] as String?,
        createdAt: map['created_at'] as String,
      );
}
