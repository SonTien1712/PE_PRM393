class CategoryTotal {
  const CategoryTotal({required this.category, required this.total});

  final String category;
  final int total;

  factory CategoryTotal.fromMap(Map<String, Object?> map) => CategoryTotal(
    category: map['category'] as String,
    total: (map['total'] as num).toInt(),
  );

  Map<String, Object?> toMap() => {'category': category, 'total': total};
}
