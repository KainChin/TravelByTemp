// ignore_for_file: use_string_in_part_of_directives

part of route_analysis;

enum TransportMode { motorbike, car, coach, train, ferry, flight }

class TransportAvailability {
  const TransportAvailability({
    required this.mode,
    required this.isAvailable,
    required this.reason,
  });

  final TransportMode mode;
  final bool isAvailable;
  final String reason;
}

class TransportOption {
  const TransportOption({
    required this.mode,
    required this.isAvailable,
    required this.reason,
    required this.durationHours,
    required this.estimatedCostVnd,
  });

  final TransportMode mode;
  final bool isAvailable;
  final String reason;
  final double durationHours;
  final double estimatedCostVnd;
}

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

  RouteLeg copyWith({
    int? order,
    String? fromName,
    Destination? to,
    double? distanceKm,
    TransportMode? recommendedMode,
    String? reason,
    bool? isGoogleEstimate,
  }) {
    return RouteLeg(
      order: order ?? this.order,
      fromName: fromName ?? this.fromName,
      to: to ?? this.to,
      distanceKm: distanceKm ?? this.distanceKm,
      recommendedMode: recommendedMode ?? this.recommendedMode,
      reason: reason ?? this.reason,
      isGoogleEstimate: isGoogleEstimate ?? this.isGoogleEstimate,
    );
  }

  double get motorbikeHours => distanceKm / 45;
  double get carHours => distanceKm / 65;
  double get trainHours => distanceKm / 55;
  double get flightHours => 2.5 + distanceKm / 650;

  double get estimatedCostVnd {
    switch (recommendedMode) {
      case TransportMode.motorbike:
        return max(25000, distanceKm * 900);
      case TransportMode.car:
        return max(90000, distanceKm * 11500);
      case TransportMode.coach:
        return max(120000, distanceKm * 850);
      case TransportMode.train:
        return max(160000, distanceKm * 950);
      case TransportMode.ferry:
        return max(185000, distanceKm * 1800);
      case TransportMode.flight:
        return _flightFareEstimateVnd(fromName, to.name, distanceKm);
    }
  }

  double get recommendedHours {
    switch (recommendedMode) {
      case TransportMode.motorbike:
        return motorbikeHours;
      case TransportMode.car:
        return carHours;
      case TransportMode.coach:
        return carHours * 1.08;
      case TransportMode.train:
        return trainHours;
      case TransportMode.ferry:
        return 1.0 + distanceKm / 35;
      case TransportMode.flight:
        return flightHours;
    }
  }

  bool get usesFlight => recommendedMode == TransportMode.flight;
}


