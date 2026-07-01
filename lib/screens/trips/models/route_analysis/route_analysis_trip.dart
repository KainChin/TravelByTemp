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
    if (legs.length >= 4 || transferCount >= 3) return 'Phuc tap';
    if (legs.length == 3 || transferCount == 2) return 'Trung binh';
    return 'Thuan tien';
  }

  String get convenienceBadge => 'Do thuan tien: $convenienceLevel';

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
    if (hasLongFlight && optimizedHours <= 8) return 'Nhanh nhat';
    if (roadOnly && estimatedRouteCostVnd < 900000) return 'Tiet kiem nhat';
    return 'Can bang thoi gian va chi phi';
  }

  List<String> get aiBadges => [
        if (isConstraintOptimalRoute) 'AI de xuat',
        routeStrategy,
        convenienceBadge,
      ];

  List<String> get importantNotes {
    final notes = <String>[];
    if (hasFlightLeg) notes.add('Nen dat ve may bay truoc 7-14 ngay.');
    if (hasFerryLeg) {
      notes.add('Can kiem tra lich tau/pha truoc khi khoi hanh.');
    }
    if (optimizedHours >= 8) {
      notes.add('Chuyen di dai, nen co thoi gian nghi giua duong.');
    }
    if (legs.any((leg) => leg.recommendedMode == TransportMode.coach && leg.distanceKm > 250)) {
      notes.add('Chang duong bo dai co the bi anh huong boi un tac.');
    }
    return notes.take(3).toList();
  }

  String get aiRecommendation {
    final sentences = <String>[
      'Phuong tien kha dung duoc backend xac dinh tu du lieu transport hub va route.',
    ];
    if (hasFlightLeg) {
      sentences.add('Chang bay giup rut ngan thoi gian cho tuyen dai.');
    } else if (hasFerryLeg) {
      sentences.add('Chang pha/tau cao toc can theo lich van hanh thuc te.');
    } else if (convenienceLevel == 'Thuan tien') {
      sentences.add('Lo trinh it trung chuyen va de thuc hien.');
    } else {
      sentences.add('Lo trinh can can bang giua thoi gian, chi phi va trung chuyen.');
    }
    if (needsTransportChange) {
      sentences.add('Nen chua thoi gian noi chuyen giua cac chang.');
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
          reason: 'Dang cho backend phan tich phuong tien kha dung.',
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
