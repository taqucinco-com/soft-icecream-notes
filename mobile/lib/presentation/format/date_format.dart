/// `yyyy-MM-dd`形式にフォーマットする。`intl`パッケージを追加せずに済む簡易実装。
String formatYmd(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
