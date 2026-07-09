// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

void _showRatedPlacesSheet(BuildContext context, Object? day) {
  final places = _ratedPlacesFor(day);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.72,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Địa điểm gợi ý 4 sao trở lên',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Các điểm phù hợp với lịch trình trong ngày để bạn tham khảo thêm.',
                  style: TextStyle(color: _TripItineraryResultScreenState._muted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: places.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _RatedPlaceTile(place: places[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

List<_RatedPlace> _ratedPlacesFor(Object? day) {
  final activities = _activitiesFor(day);
  final rated = <_RatedPlace>[];
  for (var i = 0; i < activities.length; i++) {
    final activity = Map<String, dynamic>.from(activities[i]);
    final rating = _activityRatingValue(activity);
    if (rating >= 4) {
      final label = '${activity['destination'] ?? _activityTitle(activity)}'.trim();
      rated.add(
        _RatedPlace(
          name: label.isEmpty ? _activityTitle(activity) : label,
          category: _activityCategory(activity),
          rating: rating,
          note: '${activity['note'] ?? 'Phù hợp với lịch trình hiện tại.'}',
          activity: activity,
        ),
      );
    }
  }

  if (rated.isNotEmpty) return rated.take(8).toList();
  return _fallbackRatedPlaces(activities).take(8).toList();
}

List<_RatedPlace> _fallbackRatedPlaces(List<Map<String, dynamic>> activities) {
  final seedActivity = activities.isNotEmpty ? activities.first : const <String, dynamic>{};
  final destination = '${seedActivity['destination'] ?? _activityTitle(seedActivity)}'.trim();
  final city = destination.isEmpty || destination == 'Hoạt động' ? 'khu vực này' : destination;
  final category = activities.isEmpty ? 'tham quan' : _activityCategory(activities.first);
  final curated = _curatedRatedPlaceTemplates(city);
  if (curated.isNotEmpty) {
    return curated
        .where((item) => category == 'tham quan' || item.category == category || item.rating >= 4.5)
        .map(
          (item) => _RatedPlace(
            name: item.name,
            category: item.category,
            rating: item.rating,
            note: item.note,
            activity: {
              'destination': item.name,
              'placeName': item.name,
              'activity': item.name,
              'category': item.category,
              'rating': item.rating,
            },
          ),
        )
        .toList();
  }
  final templates = <({String name, String category, double rating, String note})>[
    (
      name: 'Quán đặc sản địa phương gần $city',
      category: 'ăn uống',
      rating: 4.6,
      note: 'Ưu tiên nơi có đánh giá tốt, hợp để ăn trưa hoặc ăn tối.'
    ),
    (
      name: 'Cafe view đẹp tại $city',
      category: 'ăn uống',
      rating: 4.5,
      note: 'Phù hợp để nghỉ giữa lịch trình và chụp ảnh nhẹ.'
    ),
    (
      name: 'Điểm check-in nổi bật ở $city',
      category: 'tham quan',
      rating: 4.7,
      note: 'Nên đi khung giờ sáng hoặc chiều để đỡ đông.'
    ),
    (
      name: 'Khu trải nghiệm văn hóa/thiên nhiên $city',
      category: 'tham quan',
      rating: 4.4,
      note: 'Phù hợp nếu muốn thêm hoạt động ngoài trời hoặc trải nghiệm địa phương.'
    ),
  ];
  return templates
      .where((item) => category == 'tham quan' || item.category == category || item.rating >= 4.5)
      .map(
        (item) => _RatedPlace(
          name: item.name,
          category: item.category,
          rating: item.rating,
          note: item.note,
          activity: {
            'destination': item.name,
            'activity': item.name,
            'category': item.category,
            'rating': item.rating,
          },
        ),
      )
      .toList();
}

double _activityRatingValue(Map<String, dynamic> activity) {
  final value = activity['rating'] ?? activity['stars'] ?? activity['reviewScore'];
  if (value is num) return value.toDouble();
  if (value is String) {
    final match = RegExp(r'\d+([.,]\d+)?').firstMatch(value);
    return double.tryParse(match?.group(0)?.replaceAll(',', '.') ?? '') ?? 0;
  }
  return 0;
}

List<({String name, String category, double rating, String note})> _curatedRatedPlaceTemplates(String city) {
  final value = _normalizeText(city);
  if (value.contains('ben tre')) {
    return const [
      (name: 'Cồn Phụng', category: 'tham quan', rating: 4.6, note: 'Điểm tham quan sông nước dễ đưa vào lịch trình Bến Tre.'),
      (name: 'Khu du lịch Lan Vương', category: 'tham quan', rating: 4.5, note: 'Phù hợp nhóm bạn hoặc gia đình, có nhiều hoạt động trải nghiệm.'),
      (name: 'Chợ Bến Tre', category: 'ăn uống', rating: 4.4, note: 'Có nhiều món địa phương và dễ tìm trên Google Maps.'),
      (name: 'Làng hoa Chợ Lách', category: 'tham quan', rating: 4.5, note: 'Phù hợp chụp ảnh, thiên nhiên và lịch trình nhẹ.'),
      (name: 'Nhà cổ Huỳnh Phủ', category: 'tham quan', rating: 4.4, note: 'Gợi ý văn hóa, kiến trúc và lịch sử địa phương.'),
    ];
  }
  if (value.contains('ha noi')) {
    return const [
      (name: 'Hồ Hoàn Kiếm', category: 'tham quan', rating: 4.7, note: 'Dễ đi, phù hợp hầu hết lịch trình Hà Nội.'),
      (name: 'Văn Miếu - Quốc Tử Giám', category: 'tham quan', rating: 4.6, note: 'Gợi ý văn hóa, chụp ảnh và lịch sử.'),
      (name: 'Cafe Giảng', category: 'ăn uống', rating: 4.5, note: 'Điểm cà phê trứng nổi tiếng để tham khảo.'),
      (name: 'Chợ Đồng Xuân', category: 'ăn uống', rating: 4.3, note: 'Phù hợp ăn uống, mua sắm và khám phá phố cổ.'),
    ];
  }
  if (value.contains('da nang')) {
    return const [
      (name: 'Bãi biển Mỹ Khê', category: 'tham quan', rating: 4.6, note: 'Điểm biển nổi bật, dễ kết hợp trong ngày.'),
      (name: 'Bán đảo Sơn Trà', category: 'tham quan', rating: 4.7, note: 'Phù hợp thiên nhiên, ngắm cảnh và chụp ảnh.'),
      (name: 'Chợ Cồn', category: 'ăn uống', rating: 4.4, note: 'Nhiều món địa phương, hợp lịch trình ẩm thực.'),
      (name: 'Cầu Rồng', category: 'tham quan', rating: 4.6, note: 'Nên đi buổi tối nếu muốn xem phun lửa/phun nước.'),
    ];
  }
  if (value.contains('phu quoc')) {
    return const [
      (name: 'Bãi Sao', category: 'tham quan', rating: 4.5, note: 'Gợi ý biển đẹp, phù hợp nghỉ dưỡng và chụp ảnh.'),
      (name: 'Dinh Cậu', category: 'tham quan', rating: 4.4, note: 'Dễ đi, hợp ngắm hoàng hôn và dạo nhẹ.'),
      (name: 'Chợ đêm Phú Quốc', category: 'ăn uống', rating: 4.3, note: 'Phù hợp ăn tối và khám phá địa phương.'),
      (name: 'Grand World Phú Quốc', category: 'tham quan', rating: 4.5, note: 'Gợi ý buổi tối hoặc nhóm bạn/gia đình.'),
    ];
  }
  if (value.contains('da lat')) {
    return const [
      (name: 'Hồ Xuân Hương', category: 'tham quan', rating: 4.6, note: 'Dễ đi, hợp dạo nhẹ và chụp ảnh.'),
      (name: 'Ga Đà Lạt', category: 'tham quan', rating: 4.5, note: 'Điểm check-in kiến trúc nổi bật.'),
      (name: 'Chợ đêm Đà Lạt', category: 'ăn uống', rating: 4.3, note: 'Phù hợp ăn tối, mua sắm và dạo đêm.'),
      (name: 'Tiệm cà phê Túi Mơ To', category: 'ăn uống', rating: 4.5, note: 'Cafe view đẹp để tham khảo.'),
    ];
  }
  return const [];
}

class _RatedPlace {
  const _RatedPlace({
    required this.name,
    required this.category,
    required this.rating,
    required this.note,
    required this.activity,
  });

  final String name;
  final String category;
  final double rating;
  final String note;
  final Map<String, dynamic> activity;
}


