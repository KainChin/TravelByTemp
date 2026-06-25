import 'dart:math';

import 'destination.dart';

enum TransportMode { motorbike, car, train, flight }

class RouteLeg {
  const RouteLeg({
    required this.order,
    required this.fromName,
    required this.to,
    required this.distanceKm,
    required this.recommendedMode,
    required this.reason,
    this.isGoogleEstimate = false,
  });

  final int order;
  final String fromName;
  final Destination to;
  final double distanceKm;
  final TransportMode recommendedMode;
  final String reason;
  final bool isGoogleEstimate;

  String get routeLabel => '$fromName -> ${to.name}';

  double get motorbikeHours => distanceKm / 45;
  double get carHours => distanceKm / 65;
  double get trainHours => distanceKm / 55;
  double get flightHours => 2.5 + distanceKm / 650;

  double get recommendedHours {
    switch (recommendedMode) {
      case TransportMode.motorbike:
        return motorbikeHours;
      case TransportMode.car:
        return carHours;
      case TransportMode.train:
        return trainHours;
      case TransportMode.flight:
        return flightHours;
    }
  }

  bool get usesFlight => recommendedMode == TransportMode.flight;
}

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

  bool get hasFlightLeg => legs.any((leg) => leg.usesFlight);
  double get totalDistanceKm => legs.fold(0, (sum, leg) => sum + leg.distanceKm);
  double get optimizedHours => legs.fold(0, (sum, leg) => sum + leg.recommendedHours);
  double get motorbikeHours => legs.fold(0, (sum, leg) => sum + leg.motorbikeHours);
  double get carHours => legs.fold(0, (sum, leg) => sum + leg.carHours);
  double get flightHours => legs.fold(0, (sum, leg) {
        final value = leg.distanceKm > 500 ? leg.flightHours : leg.carHours;
        return sum + value;
      });

  String get routeTitle {
    final names = [departure.name, ...destinations.map((e) => e.destination.name)];
    return names.join(' -> ');
  }

  static TripRouteAnalysis from({
    required String departurePoint,
    required List<SelectedDestination> selectedDestinations,
    Destination? departure,
  }) {
    final start = departure ?? DestinationCatalog.hoChiMinh.copyWithName(departurePoint);

    final legs = <RouteLeg>[];
    var current = start;
    var currentName = start.name;
    for (var i = 0; i < selectedDestinations.length; i++) {
      final to = selectedDestinations[i].destination;
      final distance = _distanceKm(
        current.latitude,
        current.longitude,
        to.latitude,
        to.longitude,
      );
      final mode = _recommendedMode(distance, current.region, to.region);
      legs.add(
        RouteLeg(
          order: i + 1,
          fromName: currentName,
          to: to,
          distanceKm: distance,
          recommendedMode: mode,
          reason: _reason(distance, current.region, to.region),
        ),
      );
      current = to;
      currentName = to.name;
    }

    final normalized = selectedDestinations.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final leg = legs[index];
      return SelectedDestination(
        destination: item.destination,
        fromLabel: leg.fromName,
        distanceKm: leg.distanceKm,
        startDate: item.startDate,
        endDate: item.endDate,
      );
    }).toList();

    return TripRouteAnalysis(
      routeId: null,
      departure: start,
      destinations: normalized,
      legs: legs,
    );
  }

  factory TripRouteAnalysis.fromApi(Map<String, dynamic> json) {
    final departureJson = json['departure'] as Map<String, dynamic>;
    final destinationJson = json['destinations'] as List? ?? const [];
    final legJson = json['legs'] as List? ?? const [];
    final departure = _placeFromJson(departureJson);
    final destinations = destinationJson
        .whereType<Map<String, dynamic>>()
        .map(_placeFromJson)
        .toList();
    final legs = legJson.whereType<Map<String, dynamic>>().map((item) {
      return RouteLeg(
        order: item['order'] as int? ?? 1,
        fromName: item['fromName'] as String? ?? '',
        to: _placeFromJson(item['to'] as Map<String, dynamic>),
        distanceKm: (item['distanceKm'] as num?)?.toDouble() ?? 0,
        recommendedMode: _modeFromApi(item['recommendedMode'] as String?),
        reason: item['reason'] as String? ?? '',
        isGoogleEstimate: item['isGoogleEstimate'] as bool? ?? false,
      );
    }).toList();

    return TripRouteAnalysis(
      routeId: json['routeId'] as String?,
      departure: departure,
      destinations: destinations.asMap().entries.map((entry) {
        final leg = legs.length > entry.key ? legs[entry.key] : null;
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

  static TransportMode _modeFromApi(String? value) {
    switch (value) {
      case 'motorbike':
        return TransportMode.motorbike;
      case 'car':
        return TransportMode.car;
      case 'train':
        return TransportMode.train;
      case 'flight':
        return TransportMode.flight;
      default:
        return TransportMode.car;
    }
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

  static TransportMode _recommendedMode(double distanceKm, String fromRegion, String toRegion) {
    if (distanceKm < 150 && fromRegion == toRegion) return TransportMode.motorbike;
    if (distanceKm < 150) return TransportMode.car;
    if (distanceKm <= 500) return TransportMode.train;
    return TransportMode.flight;
  }

  static String _reason(double distanceKm, String fromRegion, String toRegion) {
    if (distanceKm < 150) return 'Chặng ngắn, linh hoạt đi xe máy hoặc ô tô.';
    if (distanceKm <= 500) return 'Chặng trung bình, ưu tiên ô tô khách hoặc tàu hỏa.';
    if (fromRegion != toRegion) return 'Di chuyển liên miền, máy bay tiết kiệm thời gian.';
    return 'Khoảng cách dài, nên ưu tiên máy bay nếu ngân sách phù hợp.';
  }
}

String transportLabel(TransportMode mode) {
  switch (mode) {
    case TransportMode.motorbike:
      return 'Xe máy';
    case TransportMode.car:
      return 'Ô tô';
    case TransportMode.train:
      return 'Tàu/xe khách';
    case TransportMode.flight:
      return 'Máy bay';
  }
}

String formatHours(double hours) {
  if (hours < 1) return '${(hours * 60).round()} phút';
  final h = hours.floor();
  final m = ((hours - h) * 60).round();
  if (m == 0) return '$h giờ';
  return '$h giờ $m phút';
}
