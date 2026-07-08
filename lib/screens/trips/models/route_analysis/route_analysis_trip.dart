// ignore_for_file: use_string_in_part_of_directives

part of route_analysis;

class TripRouteAnalysis {
  const TripRouteAnalysis({
    this.routeId,
    required this.departure,
    required this.destinations,
    required this.legs,
  });

  final String? routeId;
  final Destination departure;
  final List<SelectedDestination> destinations;
  final List<RouteLeg> legs;

  TripRouteAnalysis copyWith({
    String? routeId,
    Destination? departure,
    List<SelectedDestination>? destinations,
    List<RouteLeg>? legs,
  }) {
    return TripRouteAnalysis(
      routeId: routeId ?? this.routeId,
      departure: departure ?? this.departure,
      destinations: destinations ?? this.destinations,
      legs: legs ?? this.legs,
    );
  }

  bool get hasFlightLeg => legs.any((leg) => leg.usesFlight);
  bool get hasFerryLeg =>
      legs.any((leg) => leg.recommendedMode == TransportMode.ferry);
  bool get isConstraintOptimalRoute => legs.isNotEmpty;
  double get totalDistanceKm => legs.fold(0, (sum, leg) => sum + leg.distanceKm);
  double get optimizedHours => legs.fold(0, (sum, leg) => sum + leg.recommendedHours);
  double get estimatedRouteCostVnd =>
      legs.fold(0, (sum, leg) => sum + leg.estimatedCostVnd);

  double budgetUsagePercent(double budgetVnd) {
    if (budgetVnd <= 0) return 0;
    return estimatedRouteCostVnd / budgetVnd * 100;
  }

  int get transferCount {
    var count = legs.fold(0, (sum, leg) => sum + leg.segmentTransferCount);
    for (var i = 1; i < legs.length; i++) {
      if (legs[i].recommendedMode != legs[i - 1].recommendedMode) count++;
    }
    return count;
  }

  bool get needsTransportChange => transferCount > 0;

  String get convenienceLevel {
    if (legs.length >= 4 || transferCount >= 3) return 'Phức tạp';
    if (legs.length == 3 || transferCount == 2) return 'Trung bình';
    return 'Thuận tiện';
  }

  String get convenienceBadge => 'Độ thuận tiện: $convenienceLevel';

  String get routeStrategy {
    final hasLongFlight = legs.any(
      (leg) => leg.recommendedMode == TransportMode.flight && leg.distanceKm > 500,
    );
    final roadOnly = legs.every(
      (leg) =>
          leg.recommendedMode == TransportMode.motorbike ||
          leg.recommendedMode == TransportMode.car ||
          leg.recommendedMode == TransportMode.coach,
    );
    if (hasLongFlight && optimizedHours <= 8) return 'Nhanh nhất';
    if (roadOnly && estimatedRouteCostVnd < 900000) return 'Tiết kiệm nhất';
    return 'Cân bằng thời gian và chi phí';
  }

  List<String> get aiBadges => [
        if (isConstraintOptimalRoute) 'AI đề xuất',
        routeStrategy,
        convenienceBadge,
      ];

  List<String> get importantNotes {
    final notes = <String>[];
    if (hasFlightLeg) notes.add('Nên đặt vé máy bay trước 7-14 ngày.');
    if (hasFerryLeg) {
      notes.add('Cần kiểm tra lịch tàu/phà trước khi khởi hành.');
    }
    if (optimizedHours >= 8) {
      notes.add('Chuyến đi dài, nên có thời gian nghỉ giữa đường.');
    }
    if (legs.any((leg) => leg.recommendedMode == TransportMode.coach && leg.distanceKm > 250)) {
      notes.add('Chặng đường bộ dài có thể bị ảnh hưởng bởi ùn tắc.');
    }
    return notes.take(3).toList();
  }

  String get aiRecommendation {
    final sentences = <String>[
      'Phương tiện đã được AI tính toán tự động dựa trên khoảng cách và các nhà ga/sân bay.',
    ];
    if (hasFlightLeg) {
      sentences.add('Chặng bay giúp rút ngắn thời gian cho tuyến dài.');
    } else if (hasFerryLeg) {
      sentences.add('Chặng phà/tàu cao tốc cần theo lịch vận hành thực tế.');
    } else if (convenienceLevel == 'Thuận tiện') {
      sentences.add('Lộ trình ít trung chuyển và dễ thực hiện.');
    } else {
      sentences.add('Lộ trình cần cân bằng giữa thời gian, chi phí và trung chuyển.');
    }
    if (needsTransportChange) {
      sentences.add('Nên chừa thời gian nối chuyến giữa các chặng.');
    }
    return sentences.take(3).join(' ');
  }

  String get routeTitle {
    final names = [departure.name, ...destinations.map((e) => e.destination.name)];
    return names.join(' -> ');
  }

  static TripRouteAnalysis from({
    required String departurePoint,
    required List<SelectedDestination> selectedDestinations,
    Destination? departure,
    double? budgetPerPerson,
  }) {
    final start = departure ??
        Destination(
          id: 'departure',
          name: departurePoint,
          region: '',
          latitude: 0,
          longitude: 0,
        );

    final legs = <RouteLeg>[];
    var current = start;
    var order = 1;
    for (final item in selectedDestinations) {
      final to = item.destination;
      final distance = _distanceKm(
        current.latitude,
        current.longitude,
        to.latitude,
        to.longitude,
      );
      legs.add(
        RouteLeg(
          order: order++,
          fromName: current.name,
          to: to,
          distanceKm: distance,
          recommendedMode: TransportMode.car,
          reason: 'Đang chờ AI phân tích phương tiện khả dụng.',
        ),
      );
      current = to;
    }

    return TripRouteAnalysis(
      routeId: null,
      departure: start,
      destinations: selectedDestinations,
      legs: legs,
    );
  }

  factory TripRouteAnalysis.fromApi(
    Map<String, dynamic> json, {
    double? budgetPerPerson,
  }) {
    final departureJson = json['departure'] as Map<String, dynamic>;
    final destinationJson = json['destinations'] as List? ?? const [];
    final legJson = json['legs'] as List? ?? const [];
    final departure = _placeFromJson(departureJson);
    final destinations = destinationJson
        .whereType<Map<String, dynamic>>()
        .map(_placeFromJson)
        .toList();
    final legs = legJson.whereType<Map<String, dynamic>>().map((item) {
      final transportOptionsJson = item['transportOptions'] as List? ??
          item['TransportOptions'] as List? ??
          item['options'] as List? ??
          const [];
      return RouteLeg(
        order: item['order'] as int? ?? 1,
        fromName: item['fromName'] as String? ?? '',
        to: _placeFromJson(item['to'] as Map<String, dynamic>),
        distanceKm: (item['distanceKm'] as num?)?.toDouble() ?? 0,
        recommendedMode: _modeFromApi(item['recommendedMode'] as String?),
        reason: item['reason'] as String? ?? '',
        isGoogleEstimate: item['isGoogleEstimate'] as bool? ?? false,
        durationHours: (item['durationHours'] as num?)?.toDouble() ??
            (item['estimatedDuration'] as num?)?.toDouble(),
        estimatedCostVndOverride:
            (item['estimatedCostVnd'] as num?)?.toDouble() ??
            (item['estimatedCost'] as num?)?.toDouble(),
        transportOptions: transportOptionsJson
            .whereType<Map<String, dynamic>>()
            .map(TransportOption.fromJson)
            .toList(),
      );
    }).toList();

    return TripRouteAnalysis(
      routeId: json['routeId'] as String?,
      departure: departure,
      destinations: destinations.asMap().entries.map((entry) {
        final leg = _lastLegTo(legs, entry.value.id);
        return SelectedDestination(
          destination: entry.value,
          fromLabel: leg?.fromName ?? departure.name,
          distanceKm: leg?.distanceKm ?? 0,
        );
      }).toList(),
      legs: legs,
    );
  }

  static Destination _placeFromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      region: json['region'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  static double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const radius = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return radius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double degree) => degree * pi / 180;

  static RouteLeg? _lastLegTo(List<RouteLeg> legs, String destinationId) {
    for (var i = legs.length - 1; i >= 0; i--) {
      if (legs[i].to.id == destinationId) return legs[i];
    }
    return null;
  }
}

TransportMode _modeFromApi(String? value) {
  switch (value) {
    case 'motorbike':
      return TransportMode.motorbike;
    case 'car':
      return TransportMode.car;
    case 'coach':
      return TransportMode.coach;
    case 'train':
      return TransportMode.train;
    case 'ferry':
      return TransportMode.ferry;
    case 'flight':
      return TransportMode.flight;
    default:
      return TransportMode.car;
  }
}
