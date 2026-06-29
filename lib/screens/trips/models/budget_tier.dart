class BudgetTier {
  const BudgetTier(this.value, this.label);

  final double value;
  final String label;

  static const double minBudget = 500000;
  static const double maxBudget = 100000000;

  static const List<BudgetTier> quickChoices = [
    BudgetTier(1000000, '1 trieu'),
    BudgetTier(3000000, '3 trieu'),
    BudgetTier(5000000, '5 trieu'),
    BudgetTier(10000000, '10 trieu'),
    BudgetTier(20000000, '20 trieu'),
    BudgetTier(50000000, '50 trieu'),
  ];

  static String formatCurrency(num value) {
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
    return '${buffer}d';
  }

  static double parseCurrency(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return minBudget;
    return double.parse(digits).clamp(minBudget, maxBudget).toDouble();
  }
}
