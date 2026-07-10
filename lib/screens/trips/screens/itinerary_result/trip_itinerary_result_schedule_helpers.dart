// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

List<Map<String, dynamic>> _normalizeDays(Object? raw) {
  final source = raw is List ? raw : const [];
  final days = source.asMap().entries.map((entry) {
    final map = Map<String, dynamic>.from(entry.value is Map ? entry.value as Map : const {});
    map['day'] ??= entry.key + 1;
    final activities = _activitiesFor(map).map((item) => Map<String, dynamic>.from(item)).toList();
    map['activities'] = _expandActivities(_dedupeActivities(activities), map['day'] as int);
    return map;
  }).toList();
  return days.isEmpty
      ? [
          {'day': 1, 'activities': _expandActivities(const [], 1)}
        ]
      : days;
}

/// Loại bỏ activity trùng lặp trong cùng 1 ngày. Key = time + destination
/// (lowercase + trim). Giữ bản xuất hiện đầu tiên, bỏ các bản sau.
///
/// Lý do cần:
/// - AI đôi khi lặp cùng 1 địa điểm ở nhiều mốc khác nhau (vd 1 quán ăn
///   xuất hiện 2 lần trong ngày), gây khó chịu và sai lệch thống kê.
/// - User edit/save lại cũng có thể tạo duplicate.
///
/// Nếu user cố ý thêm lại cùng địa điểm (vd muốn ghé 2 lần trong ngày),
/// họ có thể bấm "Thêm" lại – key được tính lại từ form.
List<Map<String, dynamic>> _dedupeActivities(List<Map<String, dynamic>> input) {
  if (input.length < 2) return input;
  final seen = <String>{};
  final out = <Map<String, dynamic>>[];
  for (final item in input) {
    final time = '${item['time'] ?? ''}'.trim();
    final destination = '${item['destination'] ?? _activityTitle(item)}'
        .trim()
        .toLowerCase();
    // Bỏ qua nếu time rỗng VÀ destination rỗng (entry placeholder)
    if (time.isEmpty && destination.isEmpty) continue;
    final key = '$time|$destination';
    if (seen.add(key)) {
      out.add(item);
    }
  }
  return out;
}

/// Nếu dữ liệu từ backend/AI đã có activities thì giữ nguyên.
/// Nếu rỗng thì KHÔNG tự fill template giống nhau cho mọi ngày — để trống và
/// hiển thị empty state để user tự thêm hoạt động, tránh các ngày bị trùng.
List<Map<String, dynamic>> _expandActivities(List<Map<String, dynamic>> input, int day) {
  if (input.isNotEmpty) return input;
  // Chỉ thêm 1 dòng "khởi đầu ngày" tối thiểu để user không thấy trang trống trơn.
  return [
    {
      'time': '08:00',
      'destination': 'Điểm đến ngày $day',
      'activity': 'Bắt đầu hành trình ngày $day',
      'note': 'Bấm "Thêm" để bổ sung hoạt động cho ngày này.',
      'duration': '30 phút',
      'category': 'tham quan',
      'estimatedCost': 0,
    },
  ];
}

List<Map<String, dynamic>> _activitiesFor(Object? day) {
  final data = day is Map ? day : const {};
  final raw = data['activities'] ?? data['schedule'] ?? data['items'];
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
}

String _activityTitle(Object? activity) {
  final data = activity is Map ? activity : const {};
  return _firstNonEmpty([data['activity'], data['place'], data['title'], data['name'], data['destination']]);
}

String _firstNonEmpty(List<Object?> values) {
  for (final value in values) {
    final text = '${value ?? ''}'.trim();
    if (text.isNotEmpty && text != 'null') return text;
  }
  return 'Hoạt động';
}

int _activityCost(Map<String, dynamic> activity) {
  final value = activity['estimatedCost'] ?? activity['cost'] ?? activity['price'];
  if (value is num) return value.round();
  if (value is String) {
    final parsed = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (parsed != null) return parsed;
  }
  return 0;
}

num _dayCost(Object? day) {
  return _activitiesFor(day).fold<num>(0, (sum, item) => sum + _activityCost(item));
}



_Coordinate _coordinateOf(Map<String, dynamic> activity, String label) {
  final lat = _numValue(activity['latitude'] ?? activity['lat']);
  final lng = _numValue(activity['longitude'] ?? activity['lng']);
  if (lat != null && lng != null) return _Coordinate(lat, lng);
  return _coordinateFor(label);
}

String _distanceToNextLabel(Map<String, dynamic> current, Map<String, dynamic>? next) {
  if (next == null) return '';
  final currentLabel = '${current['destination'] ?? _activityTitle(current)}';
  final nextLabel = '${next['destination'] ?? _activityTitle(next)}';
  final currentCoordinate = _coordinateOf(current, currentLabel);
  final nextCoordinate = _coordinateOf(next, nextLabel);
  final km = const Distance().as(
    LengthUnit.Kilometer,
    LatLng(currentCoordinate.latitude, currentCoordinate.longitude),
    LatLng(nextCoordinate.latitude, nextCoordinate.longitude),
  );
  if (km < 0.2) return 'Gần điểm tiếp theo';
  return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km tới điểm kế';
}

String _activityCategory(Map<String, dynamic> activity) {
  final raw = '${activity['category'] ?? activity['type'] ?? ''}'.trim().toLowerCase();
  final normRaw = _normalizeText(raw);
  if (normRaw == 'an uong' || normRaw == 'ăn uống' || normRaw.contains('food') || normRaw.contains('restaurant') || normRaw.contains('cafe')) return 'ăn uống';
  if (normRaw.contains('hotel') || normRaw.contains('khach') || normRaw.contains('luu tru')) return 'khách sạn';
  if (normRaw.contains('transport') || normRaw.contains('di chuyen') || normRaw.contains('bus') || normRaw.contains('car')) return 'di chuyển';
  
  final title = _normalizeText('${_activityTitle(activity)} ${activity['destination'] ?? ''}');
  final tokens = title.split(RegExp(r'\s+'));
  
  if (tokens.contains('an') || tokens.contains('uong') || title.contains('nha hang') || title.contains('ca phe') || title.contains('cafe')) {
    if (!title.contains('tham quan')) {
      return 'ăn uống';
    }
  }
  if (tokens.contains('quan') && !title.contains('tham quan')) {
    return 'ăn uống';
  }
  if (title.contains('khach san') || title.contains('check in') || title.contains('homestay') || title.contains('nha nghi')) return 'khách sạn';
  if (title.contains('di chuyen') || title.contains('don xe') || title.contains('san bay') || title.contains('tau hoa') || title.contains('xe khach')) return 'di chuyển';
  return 'tham quan';
}

/// Visual metadata cho mỗi category — dùng để phân cấp thị giác trong timeline:
/// mỗi loại hoạt động có icon + màu riêng, kích thước card và line dọc khác nhau.
class _CategoryVisual {
  const _CategoryVisual({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.lineColor,
    required this.isMajor,
  });

  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color lineColor;

  /// true = card to (tham quan — điểm nhấn), false = card gọn.
  final bool isMajor;
}

_CategoryVisual _visualForCategory(String category) {
  switch (category) {
    case 'di chuyển':
      return const _CategoryVisual(
        icon: Icons.directions_bus_outlined,
        color: Color(0xFF64748B),
        bgColor: Color(0xFFF1F5F9),
        lineColor: Color(0xFF94A3B8),
        isMajor: false,
      );
    case 'ăn uống':
      return const _CategoryVisual(
        icon: Icons.restaurant_outlined,
        color: Color(0xFFF59E0B),
        bgColor: Color(0xFFFFF7ED),
        lineColor: Color(0xFFFB923C),
        isMajor: false,
      );
    case 'khách sạn':
      return const _CategoryVisual(
        icon: Icons.hotel_outlined,
        color: Color(0xFF8B5CF6),
        bgColor: Color(0xFFF5F3FF),
        lineColor: Color(0xFFA78BFA),
        isMajor: false,
      );
    case 'tham quan':
    default:
      return const _CategoryVisual(
        icon: Icons.explore_outlined,
        color: Color(0xFF008F6A),
        bgColor: Color(0xFFE6F6F0),
        lineColor: Color(0xFF34D399),
        isMajor: true,
      );
  }
}

String _activityDuration(Map<String, dynamic> activity) {
  final raw = '${activity['duration'] ?? activity['estimatedDuration'] ?? ''}'.trim();
  if (raw.isNotEmpty && raw != 'null') return raw;
  final minutes = activity['durationMinutes'];
  if (minutes is num && minutes > 0) {
    if (minutes < 60) return '${minutes.round()} phút';
    final h = minutes ~/ 60;
    final m = minutes.round() % 60;
    return m == 0 ? '$h giờ' : '$h giờ $m phút';
  }
  return '';
}

String _activityRating(Map<String, dynamic> activity) {
  final value = activity['rating'] ?? activity['stars'] ?? activity['reviewScore'];
  if (value is num && value > 0) return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}/5';
  final text = '${value ?? ''}'.trim();
  return text.isEmpty || text == 'null' ? '' : text;
}



