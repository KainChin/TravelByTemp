// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

String _categoryFromAddKind(String kind) {
  switch (kind) {
    case 'restaurant':
      return 'ăn uống';
    case 'hotel':
      return 'khách sạn';
    case 'transport':
      return 'di chuyển';
    default:
      return 'tham quan';
  }
}

String _addKindLabel(String kind) {
  switch (kind) {
    case 'place':
      return 'Địa điểm';
    case 'restaurant':
      return 'Nhà hàng';
    case 'hotel':
      return 'Khách sạn';
    case 'transport':
      return 'Phương tiện di chuyển';
    default:
      return 'Hoạt động';
  }
}

Map<String, dynamic> _newActivity(String kind) {
  final category = _categoryFromAddKind(kind);
  final label = _addKindLabel(kind);
  return {
    'time': kind == 'restaurant' ? '12:00' : '09:30',
    'activity': kind == 'transport' ? 'Di chuyển giữa các điểm' : label,
    'destination': kind == 'restaurant'
        ? 'Quán ăn gần điểm hiện tại'
        : kind == 'hotel'
            ? 'Khách sạn đề xuất'
            : kind == 'place'
                ? 'Điểm tham quan gần đây'
                : '',
    'category': category,
    'duration': kind == 'transport' ? '45 phút' : '90 phút',
    'estimatedCost': kind == 'hotel'
        ? 680000
        : kind == 'restaurant'
            ? 145000
            : kind == 'transport'
                ? 95000
                : 120000,
    'note': 'Được thêm từ gợi ý AI, có thể chỉnh sửa lại.',
  };
}

String _normalizeText(String value) {
  return value.toLowerCase()
      .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd');
}

Future<void> _openMaps(Map<String, dynamic> activity) async {
  final query = Uri.encodeComponent('${activity['address'] ?? ''} ${activity['destination'] ?? _activityTitle(activity)}'.trim());
  await launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'), mode: LaunchMode.externalApplication);
}



