// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

num? _readBudget(Map<String, dynamic> itinerary) {
  const keys = ['budgetPerPerson', 'userBudget', 'budget', 'maxBudget', 'totalBudget'];
  for (final key in keys) {
    final value = itinerary[key];
    if (value is num && value > 0) return value;
    if (value is String) {
      final parsed = num.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
      if (parsed != null && parsed > 0) return parsed;
    }
  }
  return null;
}

String _budgetLabel(num? value) => value == null || value <= 0 ? 'Chưa chọn' : _formatMoney(value);

String _moneyOrStatus(num value, {String empty = 'Chưa có dữ liệu'}) {
  return value <= 0 ? empty : _formatMoney(value);
}



