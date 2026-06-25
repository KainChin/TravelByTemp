class BudgetTier {
  const BudgetTier(this.value, this.label);

  final double value;
  final String label;

  static const double minBudget = 500000;
  static const double maxBudget = 20000000;

  static const List<BudgetTier> quickChoices = [
    BudgetTier(1000000, '1 triệu'),
    BudgetTier(3000000, '3 triệu'),
    BudgetTier(5000000, '5 triệu'),
    BudgetTier(10000000, '10 triệu'),
  ];

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

  static double parseCurrency(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return minBudget;
    return double.parse(digits).clamp(minBudget, maxBudget).toDouble();
  }
}
