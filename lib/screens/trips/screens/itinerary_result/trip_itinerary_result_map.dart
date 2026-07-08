// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

class TripMapSection extends StatefulWidget {
  const TripMapSection({
    super.key,
    required this.day,
    required this.height,
  });

  final Object? day;
  final double height;

  @override
  State<TripMapSection> createState() => _TripMapSectionState();
}

class _TripMapSectionState extends State<TripMapSection> {
  // Mặc định thu gọn — ưu tiên không gian cho lịch trình. User bấm
  // "Mở rộng" để xem bản đồ chi tiết.
  bool _collapsed = true;

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final fullHeight = widget.height;
    final height = _collapsed ? 64.0 : fullHeight;
    final stops = _stopsFor(day);
    final points = stops.map((s) => s.point).toList();
    final center = points.isEmpty ? const LatLng(16.0544, 108.2022) : points.first;
    final scheme = Theme.of(context).colorScheme;
    final mapKey = ValueKey<String>(
      'trip-map-${_dayFingerprint(day)}',
    );

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _TripItineraryResultScreenState._line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (_collapsed)
            // Compact strip: tên + số stops + nút expand.
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.map_outlined, color: _TripItineraryResultScreenState._primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bản đồ — ${_mapCollapsedTitle(stops)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Positioned.fill(
              child: FlutterMap(
                key: mapKey,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: points.length <= 1 ? 12 : 11,
                  onTap: (tapPosition, point) => _showRatedPlacesSheet(context, day),
                  initialCameraFit: points.length > 1
                      ? CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints(points),
                          padding: const EdgeInsets.all(42),
                        )
                      : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.vietai.travel',
                  ),
                  if (points.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(points: points, color: scheme.primary, strokeWidth: 5),
                      ],
                    ),
                  MarkerLayer(
                    markers: stops.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final stop = entry.value;
                      return Marker(
                        point: stop.point,
                        width: 132,
                        height: 62,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: index == 1
                                    ? const Color(0xFF0B7D4B)
                                    : _TripItineraryResultScreenState._accent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                '$index',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Tooltip(
                              message: stop.label,
                              waitDuration: const Duration(milliseconds: 250),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x1A000000), blurRadius: 6),
                                  ],
                                ),
                                child: Text(
                                  stop.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap',
                        onTap: () => launchUrl(
                          Uri.parse('https://www.openstreetmap.org/copyright'),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // Các overlay chỉ hiện khi map đang mở rộng.
          if (!_collapsed) ...[
            Positioned(
              left: 14,
              top: 14,
              child: _MapBadge(stopsCount: stops.length),
            ),
            Positioned(
              left: 14,
              bottom: 14,
              child: _RatedPlacesHint(day: day, count: _ratedPlacesFor(day).length),
            ),
            const Positioned(
              right: 14,
              top: 14,
              child: _MapControls(),
            ),
          ],
          // Nút toggle collapse/expand — góc phải dưới, không đè lên map controls.
          Positioned(
            right: 14,
            bottom: 14,
            child: _MapCollapseButton(
              collapsed: _collapsed,
              onTap: () => setState(() => _collapsed = !_collapsed),
            ),
          ),
        ],
      ),
    );
  }
}

String _mapCollapsedTitle(List<dynamic> stops) {
  if (stops.isEmpty) return 'hành trình';
  return '${stops.length} điểm';
}

String _dayFingerprint(Object? day) {
  if (day is! Map) return 'empty';
  final activities = day['activities'];
  if (activities is List) {
    return activities.length.toString();
  }
  return '${day['day'] ?? 'day'}';
}

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

class _RatedPlacesHint extends StatelessWidget {
  const _RatedPlacesHint({required this.day, required this.count});

  final Object? day;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(999),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _showRatedPlacesSheet(context, day),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rate_rounded, size: 17, color: Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              Text(
                '$count địa điểm 4.0+',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatedPlaceTile extends StatelessWidget {
  const _RatedPlaceTile({required this.place});

  final _RatedPlace place;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7FAF8),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openMaps(place.activity),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _TripItineraryResultScreenState._primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.place_outlined,
                  color: _TripItineraryResultScreenState._primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _TripItineraryResultScreenState._muted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      children: [
                        _MapSmallChip(
                          icon: Icons.star_rate_rounded,
                          label: '${place.rating.toStringAsFixed(1)}/5',
                        ),
                        _MapSmallChip(
                          icon: Icons.category_outlined,
                          label: place.category,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.map_outlined, color: _TripItineraryResultScreenState._primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapSmallChip extends StatelessWidget {
  const _MapSmallChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _TripItineraryResultScreenState._primary),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.stopsCount});

  final int stopsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 12)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.route_outlined, size: 17, color: _TripItineraryResultScreenState._primary),
          const SizedBox(width: 6),
          Text(
            '$stopsCount mốc cần đi',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _MapControlButton(icon: Icons.my_location_outlined, tooltip: 'Định vị'),
        SizedBox(height: 8),
        _MapControlButton(icon: Icons.add, tooltip: 'Phóng to'),
        SizedBox(height: 8),
        _MapControlButton(icon: Icons.remove, tooltip: 'Thu nhỏ'),
        SizedBox(height: 8),
        _MapControlButton(icon: Icons.layers_outlined, tooltip: 'Lớp bản đồ'),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {},
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 19, color: _TripItineraryResultScreenState._ink),
          ),
        ),
      ),
    );
  }
}

class _MapCollapseButton extends StatelessWidget {
  const _MapCollapseButton({required this.collapsed, required this.onTap});

  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                collapsed ? Icons.expand_more : Icons.expand_less,
                size: 18,
                color: _TripItineraryResultScreenState._primary,
              ),
              const SizedBox(width: 4),
              Text(
                collapsed ? 'Mở rộng' : 'Thu gọn',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: _TripItineraryResultScreenState._primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
