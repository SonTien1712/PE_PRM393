String monthKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

(String, String) monthRange(DateTime date) {
  final start = DateTime(date.year, date.month);
  final next = DateTime(date.year, date.month + 1);
  return ('${monthKey(start)}-01', '${monthKey(next)}-01');
}
