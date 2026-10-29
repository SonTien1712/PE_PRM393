import 'package:flutter/material.dart';

import '../data/models/finance_transaction.dart';
import 'app_theme.dart';

Color categorySurface(String category, TxType type) {
  if (type == TxType.income) return AppTheme.incomeSurface;
  return switch (category) {
    'Ăn uống' => const Color(0xFFFFF3E0),
    'Đi lại' => const Color(0xFFE3F2FD),
    'Nhà ở' => const Color(0xFFF3E5F5),
    'Mua sắm' => const Color(0xFFFCE4EC),
    'Giải trí' => const Color(0xFFE8F5E9),
    'Sức khỏe' => const Color(0xFFFFEBEE),
    'Giáo dục' => const Color(0xFFE0F7FA),
    _ => AppTheme.expenseSurface,
  };
}

IconData categoryIcon(String category) => switch (category) {
  'Ăn uống' => Icons.restaurant_rounded,
  'Đi lại' => Icons.directions_car_outlined,
  'Nhà ở' => Icons.home_outlined,
  'Mua sắm' => Icons.shopping_bag_outlined,
  'Giải trí' => Icons.movie_outlined,
  'Sức khỏe' => Icons.favorite_border_rounded,
  'Giáo dục' => Icons.school_outlined,
  'Lương' => Icons.work_outline_rounded,
  'Thưởng' => Icons.card_giftcard_rounded,
  'Đầu tư' => Icons.trending_up_rounded,
  _ => Icons.category_outlined,
};
