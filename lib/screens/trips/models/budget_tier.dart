/// Một nấc giá trị cố định trên thanh trượt ngân sách (mỗi người).
class BudgetTier {
  final double value;
  final String label;

  const BudgetTier(this.value, this.label);

  static const List<BudgetTier> tiers = [
    BudgetTier(500000, '500k'),
    BudgetTier(700000, '700k'),
    BudgetTier(1000000, '1 triệu'),
    BudgetTier(2000000, '2 triệu'),
    BudgetTier(5000000, '5 triệu'),
    BudgetTier(10000000, '10 triệu+'),
  ];

  /// Định dạng số tiền kiểu "3.000.000đ".
  static String formatCurrency(double value) {
    final intValue = value.round();
    final str = intValue.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final posFromEnd = str.length - i;
      buffer.write(str[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()}đ';
  }
}