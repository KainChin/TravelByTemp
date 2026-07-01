// ignore_for_file: use_string_in_part_of_directives

part of route_analysis;

String transportLabel(TransportMode mode) {
  switch (mode) {
    case TransportMode.motorbike:
      return 'Xe may';
    case TransportMode.car:
      return 'O to';
    case TransportMode.coach:
      return 'Xe khach';
    case TransportMode.train:
      return 'Tau hoa';
    case TransportMode.ferry:
      return 'Pha/tau cao toc';
    case TransportMode.flight:
      return 'May bay';
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

List<TransportOption> _fallbackTransportOptionsForLeg(RouteLeg leg) {
  final recommendedMode = leg.recommendedMode;
  final distanceKm = leg.distanceKm;
  final currentReason = leg.reason.isEmpty
      ? 'Phuong tien hien tai cua chang nay.'
      : leg.reason;
  return [
    TransportOption(
      mode: TransportMode.car,
      isAvailable: true,
      isRecommended: recommendedMode == TransportMode.car,
      reason: recommendedMode == TransportMode.car
          ? currentReason
          : 'Co the di bang o to/taxi tren chang duong bo.',
      durationHours: _fallbackHours(distanceKm, TransportMode.car),
      estimatedCostVnd: _fallbackCost(distanceKm, TransportMode.car),
      segments: [leg.routeLabel],
    ),
    TransportOption(
      mode: TransportMode.motorbike,
      isAvailable: distanceKm <= 180,
      isRecommended: recommendedMode == TransportMode.motorbike,
      reason: distanceKm <= 180
          ? (recommendedMode == TransportMode.motorbike ? currentReason : 'Xe may phu hop hon voi chang ngan.')
          : 'Quang duong dai, xe may khong phu hop de chon.',
      durationHours: _fallbackHours(distanceKm, TransportMode.motorbike),
      estimatedCostVnd: _fallbackCost(distanceKm, TransportMode.motorbike),
      segments: [leg.routeLabel],
    ),
    TransportOption(
      mode: TransportMode.coach,
      isAvailable: distanceKm >= 40,
      isRecommended: recommendedMode == TransportMode.coach,
      reason: recommendedMode == TransportMode.coach
          ? currentReason
          : 'Xe khach phu hop cho chang lien tinh va chi phi thap.',
      durationHours: _fallbackHours(distanceKm, TransportMode.coach),
      estimatedCostVnd: _fallbackCost(distanceKm, TransportMode.coach),
      segments: [leg.routeLabel],
    ),
    TransportOption(
      mode: TransportMode.train,
      isAvailable: recommendedMode == TransportMode.train,
      isRecommended: recommendedMode == TransportMode.train,
      reason: recommendedMode == TransportMode.train
          ? currentReason
          : 'Can backend xac minh ga tau/tuyen tau phu hop cho chang nay.',
      durationHours: _fallbackHours(distanceKm, TransportMode.train),
      estimatedCostVnd: _fallbackCost(distanceKm, TransportMode.train),
      segments: [leg.routeLabel],
    ),
    TransportOption(
      mode: TransportMode.flight,
      isAvailable: recommendedMode == TransportMode.flight || distanceKm >= 150,
      isRecommended: recommendedMode == TransportMode.flight,
      reason: recommendedMode == TransportMode.flight
          ? currentReason
          : distanceKm < 150
              ? 'Khong khuyen nghi: chang ngan, may bay chi nen hien neu backend xac minh san bay hai dau.'
              : 'Co the chon may bay neu backend xac minh co san bay phu hop hai dau.',
      durationHours: _fallbackHours(distanceKm, TransportMode.flight),
      estimatedCostVnd: _fallbackCost(distanceKm, TransportMode.flight),
      segments: [leg.routeLabel],
    ),
    TransportOption(
      mode: TransportMode.ferry,
      isAvailable: recommendedMode == TransportMode.ferry,
      isRecommended: recommendedMode == TransportMode.ferry,
      reason: recommendedMode == TransportMode.ferry
          ? currentReason
          : 'Chi kha dung khi backend xac minh co ben pha/cang phu hop.',
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
  if (hours < 1) return '${(hours * 60).round()} phut';
  final h = hours.floor();
  final m = ((hours - h) * 60).round();
  if (m == 0) return '$h gio';
  return '$h gio $m phut';
}
