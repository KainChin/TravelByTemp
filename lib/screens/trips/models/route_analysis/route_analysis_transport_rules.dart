// ignore_for_file: use_string_in_part_of_directives

part of route_analysis;

String transportLabel(TransportMode mode) {
  switch (mode) {
    case TransportMode.motorbike:
      return 'Xe máy';
    case TransportMode.car:
      return 'Ô tô';
    case TransportMode.coach:
      return 'Xe khách';
    case TransportMode.train:
      return 'Tàu hỏa';
    case TransportMode.ferry:
      return 'Phà/tàu cao tốc';
    case TransportMode.flight:
      return 'Máy bay';
  }
}

List<TransportOption> transportOptionsForLeg(RouteLeg leg) {
  final checks = [
    canUseCar(leg),
    canUseMotorbike(leg),
    canUseBus(leg),
    canUseTrain(leg),
    canUseFlight(leg),
    canUseFerry(leg),
  ];
  return checks.map((item) {
    final preview = leg.copyWith(
      recommendedMode: item.mode,
      reason: item.reason,
    );
    return TransportOption(
      mode: item.mode,
      isAvailable: item.isAvailable,
      reason: item.reason,
      durationHours: preview.recommendedHours,
      estimatedCostVnd: preview.estimatedCostVnd,
    );
  }).toList();
}

TransportAvailability canUseCar(RouteLeg leg) {
  if (_routeTouchesIslandWithoutPort(leg)) {
    return const TransportAvailability(
      mode: TransportMode.car,
      isAvailable: false,
      reason: 'Ô tô không thể đi thẳng đến đảo, cần trung chuyển qua cảng hoặc sân bay.',
    );
  }
  if (_isFerryOnlyLeg(leg)) {
    return const TransportAvailability(
      mode: TransportMode.car,
      isAvailable: false,
      reason: 'Chặng này phải đi tàu/phà vì nối đất liền với đảo.',
    );
  }
  return const TransportAvailability(
    mode: TransportMode.car,
    isAvailable: true,
    reason: 'Có kết nối đường bộ, ô tô/taxi phù hợp cho chặng này.',
  );
}

TransportAvailability canUseMotorbike(RouteLeg leg) {
  if (_routeTouchesIslandWithoutPort(leg) || _isFerryOnlyLeg(leg)) {
    return const TransportAvailability(
      mode: TransportMode.motorbike,
      isAvailable: false,
      reason: 'Xe máy không phù hợp cho chặng nối đảo hoặc chặng cần tàu/phà.',
    );
  }
  if (leg.distanceKm > 180) {
    return const TransportAvailability(
      mode: TransportMode.motorbike,
      isAvailable: false,
      reason: 'Quãng đường dài, xe máy không phải lựa chọn an toàn và thực tế.',
    );
  }
  return const TransportAvailability(
    mode: TransportMode.motorbike,
    isAvailable: true,
    reason: 'Chặng ngắn có đường bộ, xe máy linh hoạt và tiết kiệm.',
  );
}

TransportAvailability canUseBus(RouteLeg leg) {
  if (_routeTouchesIslandWithoutPort(leg) || _isFerryOnlyLeg(leg)) {
    return const TransportAvailability(
      mode: TransportMode.coach,
      isAvailable: false,
      reason: 'Xe khách không thể đi thẳng đến đảo, cần trung chuyển qua cảng hoặc sân bay.',
    );
  }
  if (leg.distanceKm < 40) {
    return const TransportAvailability(
      mode: TransportMode.coach,
      isAvailable: false,
      reason: 'Chặng quá ngắn, ô tô/taxi hoặc xe máy phù hợp hơn xe khách.',
    );
  }
  return const TransportAvailability(
    mode: TransportMode.coach,
    isAvailable: true,
    reason: 'Có kết nối đường bộ, xe khách phù hợp chi phí cho chặng này.',
  );
}

TransportAvailability canUseTrain(RouteLeg leg) {
  if (_routeTouchesIslandWithoutPort(leg) || _isFerryOnlyLeg(leg)) {
    return const TransportAvailability(
      mode: TransportMode.train,
      isAvailable: false,
      reason: 'Không có tuyến tàu hỏa đi thẳng đến đảo.',
    );
  }
  if (!_hasRailName(leg.fromName) || !TripRouteAnalysis._hasRail(leg.to)) {
    return const TransportAvailability(
      mode: TransportMode.train,
      isAvailable: false,
      reason: 'Tàu hỏa không khả dụng vì một trong hai điểm không có ga phù hợp.',
    );
  }
  return const TransportAvailability(
    mode: TransportMode.train,
    isAvailable: true,
    reason: 'Hai điểm có hạ tầng đường sắt phù hợp.',
  );
}

TransportAvailability canUseFlight(RouteLeg leg) {
  if (leg.distanceKm < 250) {
    return const TransportAvailability(
      mode: TransportMode.flight,
      isAvailable: false,
      reason: 'Máy bay không phù hợp vì chặng quá ngắn.',
    );
  }
  if (!_hasNearbyAirportName(leg.fromName) || !TripRouteAnalysis._hasAirport(leg.to)) {
    return const TransportAvailability(
      mode: TransportMode.flight,
      isAvailable: false,
      reason: 'Máy bay không khả dụng vì điểm đi hoặc điểm đến không có sân bay phù hợp.',
    );
  }
  if (!_hasPracticalFlightConnection(leg)) {
    return const TransportAvailability(
      mode: TransportMode.flight,
      isAvailable: false,
      reason: 'Không có tuyến bay trực tiếp hoặc nối chuyến hợp lý cho chặng này.',
    );
  }
  return const TransportAvailability(
    mode: TransportMode.flight,
    isAvailable: true,
    reason: 'Có sân bay và khoảng cách đủ xa, máy bay giúp tiết kiệm thời gian.',
  );
}

TransportAvailability canUseFerry(RouteLeg leg) {
  if (_isFerryOnlyLeg(leg)) {
    return const TransportAvailability(
      mode: TransportMode.ferry,
      isAvailable: true,
      reason: 'Chặng nối cảng với đảo, tàu/phà là phương tiện bắt buộc.',
    );
  }
  return const TransportAvailability(
    mode: TransportMode.ferry,
    isAvailable: false,
    reason: 'Tàu/phà chỉ khả dụng khi chặng có cảng và điểm đảo.',
  );
}

bool _routeTouchesIslandWithoutPort(RouteLeg leg) {
  final toIsland = TripRouteAnalysis._isIsland(leg.to);
  final fromIsland = _isIslandName(leg.fromName);
  return (toIsland || fromIsland) && !_isPortName(leg.fromName);
}

bool _isFerryOnlyLeg(RouteLeg leg) {
  final fromPort = _isPortName(leg.fromName);
  final toIsland = TripRouteAnalysis._isIsland(leg.to);
  final fromIsland = _isIslandName(leg.fromName);
  final toPort = _isPortName(leg.to.name);
  return (fromPort && toIsland) || (fromIsland && toPort);
}

bool _hasPracticalFlightConnection(RouteLeg leg) {
  final from = _flightFarePlaceKey(leg.fromName);
  final to = _flightFarePlaceKey(leg.to.name);
  if (_domesticFlightFareVnd.containsKey(_routeFareKey(from, to))) return true;
  if (_isIslandName(leg.to.name) && TripRouteAnalysis._hasAirport(leg.to)) {
    return leg.distanceKm >= 250;
  }
  return _hasNearbyAirportName(leg.fromName) &&
      TripRouteAnalysis._hasAirport(leg.to) &&
      leg.distanceKm >= 500;
}

bool _hasAirportName(String value) {
  final normalized = _normalizeFareText(value);
  return normalized.contains('san bay') ||
      TripRouteAnalysis._airportNames.any((name) => normalized.contains(name));
}

bool _hasNearbyAirportName(String value) {
  if (_hasAirportName(value)) return true;
  final normalized = _normalizeFareText(value);
  return normalized.contains('vi tri hien tai') ||
      normalized.contains('binh duong') ||
      normalized.contains('dong nai') ||
      normalized.contains('vung tau') ||
      normalized.contains('ha long') ||
      normalized.contains('ninh binh') ||
      normalized.contains('hoi an') ||
      normalized.contains('rach gia') ||
      normalized.contains('ha tien');
}

bool _hasRailName(String value) {
  final normalized = _normalizeFareText(value);
  return TripRouteAnalysis._railNames.any((name) => normalized.contains(name));
}

bool _isPortName(String value) {
  final normalized = _normalizeFareText(value);
  return normalized.contains('cang') ||
      normalized.contains('ben pha') ||
      normalized.contains('rach gia') ||
      normalized.contains('ha tien') ||
      normalized.contains('tran de');
}

bool _isIslandName(String value) {
  final normalized = _normalizeFareText(value);
  return normalized.contains('phu quoc') || normalized.contains('con dao');
}

String formatHours(double hours) {
  if (hours < 1) return '${(hours * 60).round()} phút';
  final h = hours.floor();
  final m = ((hours - h) * 60).round();
  if (m == 0) return '$h giờ';
  return '$h giờ $m phút';
}


