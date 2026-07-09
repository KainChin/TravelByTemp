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
  if (leg.transportOptions.length > 1) return leg.transportOptions;
  if (leg.transportOptions.length == 1 &&
      leg.transportOptions.first.mode != leg.recommendedMode) {
    return leg.transportOptions;
  }
  final fallback = _fallbackTransportOptionsForLeg(leg);
  if (leg.transportOptions.isEmpty) return fallback;
  final serverOnlyOption = leg.transportOptions.first;
  return fallback
      .map((option) => option.mode == serverOnlyOption.mode ? serverOnlyOption : option)
      .toList();
}

bool _isIslandLeg(RouteLeg leg) {
  if (leg.to.isIsland) return true;
  if (Destination.isIslandName(leg.fromName)) return true;
  return false;
}

List<TransportOption> _fallbackTransportOptionsForLeg(RouteLeg leg) {
  final recommendedMode = leg.recommendedMode;
  final distanceKm = leg.distanceKm;
  final islandLeg = _isIslandLeg(leg);
  final currentReason = leg.reason.isEmpty
      ? 'Phương tiện hiện tại của chặng này.'
      : leg.reason;
  const landReason = 'Điểm đến/trung gian là đảo, phương tiện đường bộ không thể tới.';
  return [
    TransportOption(
      mode: TransportMode.car,
      isAvailable: !islandLeg,
      isRecommended: !islandLeg && recommendedMode == TransportMode.car,
      reason: islandLeg
          ? landReason
          : recommendedMode == TransportMode.car
              ? currentReason
              : 'Có thể đi bằng ô tô/taxi trên chặng đường bộ.',
      durationHours: _fallbackHours(distanceKm, TransportMode.car),
      estimatedCostVnd: _fallbackCost(distanceKm, TransportMode.car),
      segments: [leg.routeLabel],
    ),
    TransportOption(
      mode: TransportMode.motorbike,
      isAvailable: !islandLeg && distanceKm <= 180,
      isRecommended: !islandLeg && recommendedMode == TransportMode.motorbike,
      reason: islandLeg
          ? landReason
          : distanceKm > 180
              ? 'Quãng đường dài, xe máy không phù hợp để chọn.'
              : (recommendedMode == TransportMode.motorbike
                  ? currentReason
                  : 'Xe máy phù hợp hơn với chặng ngắn.'),
      durationHours: _fallbackHours(distanceKm, TransportMode.motorbike),
      estimatedCostVnd: _fallbackCost(distanceKm, TransportMode.motorbike),
      segments: [leg.routeLabel],
    ),
    TransportOption(
      mode: TransportMode.coach,
      isAvailable: !islandLeg && distanceKm >= 40,
      isRecommended: !islandLeg && recommendedMode == TransportMode.coach,
      reason: islandLeg
          ? landReason
          : recommendedMode == TransportMode.coach
              ? currentReason
              : distanceKm < 40
                  ? 'Chặng quá ngắn, xe khách thường không có tuyến phù hợp.'
                  : 'Xe khách phù hợp cho chặng liên tỉnh và chi phí thấp.',
      durationHours: _fallbackHours(distanceKm, TransportMode.coach),
      estimatedCostVnd: _fallbackCost(distanceKm, TransportMode.coach),
      segments: [leg.routeLabel],
    ),
    TransportOption(
      mode: TransportMode.train,
      isAvailable: !islandLeg && recommendedMode == TransportMode.train,
      isRecommended: !islandLeg && recommendedMode == TransportMode.train,
      reason: islandLeg
          ? landReason
          : recommendedMode == TransportMode.train
              ? currentReason
              : 'Hiện chưa có ga/tuyến tàu hỏa phù hợp cho chặng này.',
      durationHours: _fallbackHours(distanceKm, TransportMode.train),
      estimatedCostVnd: _fallbackCost(distanceKm, TransportMode.train),
      segments: [leg.routeLabel],
    ),
    TransportOption(
      mode: TransportMode.flight,
      isAvailable:
          islandLeg || recommendedMode == TransportMode.flight || distanceKm >= 150,
      isRecommended: recommendedMode == TransportMode.flight,
      reason: islandLeg
          ? 'Có chuyến bay thẳng đến đảo, nên đặt vé sớm để có giá tốt.'
          : recommendedMode == TransportMode.flight
              ? currentReason
              : distanceKm < 150
                  ? 'Chặng ngắn, máy bay chỉ nên chọn nếu có sân bay phù hợp hai đầu.'
                  : 'Có thể chọn máy bay nếu có sân bay phù hợp hai đầu.',
      durationHours: _fallbackHours(distanceKm, TransportMode.flight),
      estimatedCostVnd: _fallbackCost(distanceKm, TransportMode.flight),
      segments: [leg.routeLabel],
    ),
    TransportOption(
      mode: TransportMode.ferry,
      isAvailable: islandLeg || recommendedMode == TransportMode.ferry,
      isRecommended: recommendedMode == TransportMode.ferry,
      reason: islandLeg
          ? 'Có tuyến phà/tàu cao tốc đến đảo, nên kiểm tra lịch tàu trước khi đi.'
          : recommendedMode == TransportMode.ferry
              ? currentReason
              : 'Chỉ khả dụng khi có bến phà/cảng phù hợp tại hai đầu.',
      durationHours: _fallbackHours(distanceKm, TransportMode.ferry),
      estimatedCostVnd: _fallbackCost(distanceKm, TransportMode.ferry),
      segments: [leg.routeLabel],
    ),
  ];
}

double _fallbackHours(double distanceKm, TransportMode mode) {
  switch (mode) {
    case TransportMode.motorbike:
      return distanceKm / 45;
    case TransportMode.car:
      return distanceKm / 65;
    case TransportMode.coach:
      return distanceKm / 60;
    case TransportMode.train:
      return distanceKm / 55;
    case TransportMode.ferry:
      return 1 + distanceKm / 35;
    case TransportMode.flight:
      return 2 + distanceKm / 650;
  }
}

double _fallbackCost(double distanceKm, TransportMode mode) {
  switch (mode) {
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
      if (distanceKm < 300) return 1200000;
      if (distanceKm < 700) return 1800000;
      if (distanceKm < 1200) return 2500000;
      return 3500000;
  }
}

String formatHours(double hours) {
  if (hours < 1) return '${(hours * 60).round()} phút';
  final h = hours.floor();
  final m = ((hours - h) * 60).round();
  if (m == 0) return '$h giờ';
  return '$h giờ $m phút';
}
