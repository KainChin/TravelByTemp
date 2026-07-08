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

  /// Cached list các [MultiLegJourney] thực tế của mỗi leg, dùng cho cả
  /// UI breakdown và thống kê tổng quan. Đây là single source of truth.
  /// Lưu ý: chỉ chứa journey cho các leg có toạ độ origin hợp lệ.
  List<MultiLegJourney> get effectiveJourneys =>
      legs.map(effectiveJourneyForLeg).whereType<MultiLegJourney>().toList();

  /// Tổng khoảng cách BAO GỒM cả taxi ra/vào sân bay/cảng (dùng breakdown).
  /// Fallback về RouteLeg.distanceKm nếu leg không có journey.
  double get totalDistanceKm {
    final journeys = effectiveJourneys;
    if (journeys.isEmpty) {
      return legs.fold(0, (sum, leg) => sum + leg.distanceKm);
    }
    return journeys.fold(0.0,
        (sum, j) => sum + j.legs.fold(0.0, (s, l) => s + l.distanceKm));
  }

  /// Tổng thời gian BAO GỒM check-in, taxi, chờ boarding.
  double get optimizedHours {
    final journeys = effectiveJourneys;
    if (journeys.isEmpty) {
      return legs.fold(0, (sum, leg) => sum + leg.recommendedHours);
    }
    return journeys.fold(0.0,
        (sum, j) => sum + j.totalDurationHours);
  }

  /// Tổng chi phí BAO GỒM taxi ra/vào hub (dùng breakdown).
  double get estimatedRouteCostVnd {
    final journeys = effectiveJourneys;
    if (journeys.isEmpty) {
      return legs.fold(0, (sum, leg) => sum + leg.estimatedCostVnd);
    }
    return journeys.fold(0.0, (sum, j) => sum + j.totalCostVnd);
  }

  /// Tổng chi phí di chuyển cho cả nhóm, đã tính đúng theo từng mode:
  /// - flight/ferry/motorbike/train: nhân theo số người (mỗi người mua 1 vé)
  /// - car/coach: giữ nguyên (giá thuê nguyên phương tiện)
  ///
  /// Đã bao gồm taxi ra/vào hub (multi-leg breakdown).
  double totalTransportCostForGroup(int peopleCount) {
    final clamped = peopleCount <= 0 ? 1 : peopleCount;
    final journeys = effectiveJourneys;
    if (journeys.isEmpty) {
      // Fallback: dùng leg.estimatedCostVnd như cũ
      return legs.fold(0.0, (sum, leg) {
        final mode = leg.recommendedMode;
        final isPerTicket = mode == TransportMode.flight ||
            mode == TransportMode.ferry ||
            mode == TransportMode.motorbike ||
            mode == TransportMode.train;
        return sum + (isPerTicket ? leg.estimatedCostVnd * clamped : leg.estimatedCostVnd);
      });
    }
    return journeys.fold(0.0, (sum, j) {
      return sum + j.legs.fold(0.0, (s, l) {
        final isPerTicket = l.mode == TransportMode.flight ||
            l.mode == TransportMode.ferry ||
            l.mode == TransportMode.motorbike ||
            l.mode == TransportMode.train;
        return s + (isPerTicket ? l.costVnd * clamped : l.costVnd);
      });
    });
  }

  double budgetUsagePercent(double budgetVnd) {
    if (budgetVnd <= 0) return 0;
    return estimatedRouteCostVnd / budgetVnd * 100;
  }

  int get transferCount {
    // Đếm cả đổi mode trong mỗi sub-leg (taxi → bay → taxi). Nếu leg
    // có journey breakdown (flight/ferry) → dùng journey; nếu chỉ là
    // road-based thì tính theo inter-leg changes như cũ.
    var count = 0;
    for (final leg in legs) {
      final journey = effectiveJourneyForLeg(leg);
      if (journey != null && journey.isMultiLeg) {
        // Số lần đổi mode trong journey = số sub-leg - 1
        count += journey.legs.length - 1;
      } else {
        // Road-based: không có đổi mode trong leg
      }
    }
    // Cộng thêm số lần đổi mode giữa các leg (vd leg[0] xe khách,
    // leg[1] máy bay → +1)
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
    return 'Cân bằng thời gian & chi phí';
  }

  List<String> get aiBadges => [
        if (isConstraintOptimalRoute) 'AI đề xuất',
        routeStrategy,
        convenienceBadge,
      ];

  List<String> get importantNotes {
    final notes = <String>[];
    if (hasFlightLeg) notes.add('Nên đặt vé máy bay trước 7-14 ngày để có giá tốt.');
    if (hasFerryLeg) {
      notes.add('Kiểm tra lịch tàu/phà trước khi khởi hành.');
    }
    if (legs.any((leg) => leg.to.isIsland)) {
      notes.add('Chặng đến đảo cần dùng phà hoặc máy bay, nên đặt vé trước.');
    }
    if (optimizedHours >= 8) {
      notes.add('Hành trình khá dài, nên chừa thời gian nghỉ giữa đường.');
    }
    if (legs.any((leg) => leg.recommendedMode == TransportMode.coach && leg.distanceKm > 250)) {
      notes.add('Chặng đường bộ dài có thể bị ảnh hưởng bởi ùn tắc.');
    }
    return notes.take(3).toList();
  }

  String get aiRecommendation {
    final sentences = <String>[];
    if (hasFlightLeg) {
      sentences.add('Có chặng bay, nên đặt vé máy bay sớm 7-14 ngày để có giá tốt.');
    } else if (hasFerryLeg) {
      sentences.add('Có chặng phà/tàu cao tốc, nhớ kiểm tra lịch tàu trước chuyến đi.');
    } else if (convenienceLevel == 'Thuận tiện') {
      sentences.add('Lộ trình thuận tiện, ít phải chuyển phương tiện.');
    } else {
      sentences.add('Lộ trình cần cân nhắc giữa thời gian di chuyển và chi phí.');
    }
    if (needsTransportChange) {
      sentences.add('Có nhiều chặng khác phương tiện, nên chừa thời gian nối chuyến.');
    }
    if (legs.any((leg) => leg.to.isIsland)) {
      sentences.add('Điểm đến có đảo, chặng cuối cần đi phà hoặc máy bay.');
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
          landmassId: Destination.defaultLandmassFor(departurePoint),
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
          reason: 'Dang cho backend phan tich phuong tien kha dung.',
          from: current,
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
    final legsRaw = legJson.whereType<Map<String, dynamic>>().toList();
    final legs = <RouteLeg>[];
    var previous = departure;
    for (var i = 0; i < legsRaw.length; i++) {
      final item = legsRaw[i];
      final transportOptionsJson = item['transportOptions'] as List? ??
          item['TransportOptions'] as List? ??
          item['options'] as List? ??
          const [];
      final to = _placeFromJson(item['to'] as Map<String, dynamic>);
      legs.add(RouteLeg(
        order: item['order'] as int? ?? (i + 1),
        fromName: item['fromName'] as String? ?? previous.name,
        to: to,
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
        from: previous,
      ));
      previous = to;
    }

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
    final name = json['name'] as String? ?? '';
    return Destination(
      id: json['id'] as String? ?? '',
      name: name,
      region: json['region'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      landmassId: (json['landmassId'] as String?) ??
          Destination.defaultLandmassFor(name),
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
