// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

List<Map<String, dynamic>> _normalizeDays(Object? raw) {
  final source = raw is List ? raw : const [];
  final days = source.asMap().entries.map((entry) {
    final map = Map<String, dynamic>.from(entry.value is Map ? entry.value as Map : const {});
    map['day'] ??= entry.key + 1;
    final activities = _activitiesFor(map).map((item) => Map<String, dynamic>.from(item)).toList();
    map['activities'] = _expandActivities(activities, map['day'] as int);
    return map;
  }).toList();
  return days.isEmpty
      ? [
          {'day': 1, 'activities': _expandActivities(const [], 1)}
        ]
      : days;
}

List<Map<String, dynamic>> _expandActivities(List<Map<String, dynamic>> input, int day) {
  final base = input.toList();
  final destination = base.isEmpty ? 'Điểm đến' : '${base.first['destination'] ?? 'Điểm đến'}';
  final templates = [
    ('07:30', 'Ăn sáng địa phương', 'Thử món ăn nổi bật gần nơi lưu trú', 68000),
    ('09:00', 'Tham quan điểm chính', 'Di chuyển sớm để tránh đông và chụp ảnh đẹp', 145000),
    ('11:30', 'Nghỉ và ăn trưa', 'Chọn quán có đánh giá tốt quanh khu vực', 132000),
    ('14:00', 'Khám phá điểm gần kề', 'Tối ưu tuyến đường để không quay đầu nhiều', 118000),
    ('16:30', 'Cafe hoặc check-in', 'Khoảng nghỉ nhẹ trước buổi tối', 76000),
    ('19:00', 'Ăn tối và đi dạo', 'Kết thúc ngày với khu trung tâm hoặc chợ đêm', 184000),
  ];
  for (var i = base.length; i < templates.length; i++) {
    final t = templates[i];
    base.add({
      'time': t.$1,
      'destination': destination,
      'activity': t.$2,
      'note': t.$3,
      'duration': i == 0 || i == 2 || i == 5 ? '60 phút' : '2 giờ',
      'category': i == 0 || i == 2 || i == 5 ? 'ăn uống' : 'tham quan',
      'estimatedCost': t.$4 + day * 7000 + i * 3000,
    });
  }
  return base;
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
  final seed = _activityTitle(activity).codeUnits.fold<int>(0, (sum, code) => sum + code);
  if (value is num) return _humanizeCost(value.round(), seed);
  if (value is String) {
    final parsed = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (parsed != null) return _humanizeCost(parsed, seed);
  }
  return _humanizeCost(63000 + (seed % 17) * 11000, seed);
}

num _dayCost(Object? day) {
  return _activitiesFor(day).fold<num>(0, (sum, item) => sum + _activityCost(item));
}



String _distanceToNextLabel(Map<String, dynamic> current, Map<String, dynamic>? next) {
  if (next == null) return '';
  final currentLabel = '${current['destination'] ?? _activityTitle(current)}';
  final nextLabel = '${next['destination'] ?? _activityTitle(next)}';
  final currentCoordinate = _coordinateFor(currentLabel);
  final nextCoordinate = _coordinateFor(nextLabel);
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



