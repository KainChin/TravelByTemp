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

List<String> _budgetAnalysisNotes(Map<String, num> cost) {
  final total = cost['total'] ?? 0;
  if (total <= 0) {
    return const [
      'Chưa có đủ dữ liệu chi phí để phân tích.',
      'Hãy thêm chi phí cho hoạt động, lưu trú hoặc di chuyển để AI đánh giá tốt hơn.',
    ];
  }
  final food = cost['food'] ?? 0;
  final transport = cost['transport'] ?? 0;
  final stay = cost['accommodation'] ?? 0;
  final activity = cost['activities'] ?? 0;
  final maxEntry = {
    'ăn uống': food,
    'di chuyển': transport,
    'lưu trú': stay,
    'vé & hoạt động': activity,
  }.entries.reduce((a, b) => a.value >= b.value ? a : b);
  final saving = (total * 0.08).round();
  return [
    'Chi phí ${maxEntry.key} chiếm ${((maxEntry.value / total) * 100).round()}% tổng ngân sách.',
    transport / total < 0.12 ? 'Chi phí di chuyển khá thấp.' : 'Chi phí di chuyển đang là khoản cần theo dõi.',
    stay <= 0 ? 'Lưu trú chưa được lựa chọn.' : 'Lưu trú đã có trong kế hoạch.',
    'Có thể tiết kiệm khoảng ${_formatMoney(saving)} nếu thay đổi khách sạn hoặc nhà hàng.',
  ];
}



