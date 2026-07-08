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
      return 'Phà/Tàu cao tốc';
    case TransportMode.flight:
      return 'Máy bay';
  }
}

List<TransportOption> transportOptionsForLeg(RouteLeg leg) {
  final origin = _originFor(leg);
  final dest = leg.to;

  // Hàm helper: re-validate một option qua checkTransportAvailability để
  // đảm bảo disabled đúng với landmass / hub gần nhất. Backend có thể
  // không biết Côn Đảo là đảo → ta phải filter cuối cùng.
  TransportOption _recheck(TransportOption option) {
    final availability = checkTransportAvailability(
      mode: option.mode, origin: origin, destination: dest,
    );
    // Nếu mode không khả dụng → tắt (kèm reason rõ ràng từ client)
    if (!availability.available) {
      return option.copyWith(
        isAvailable: false,
        reason: availability.reason,
      );
    }
    // Mode khả dụng → giữ nguyên các thông tin từ server nếu có, nhưng
    // đảm bảo isAvailable=true. durationHours/costVnd từ server đã đúng
    // (server là Google estimate hoặc backend cost-aware) nên không override.
    return option.copyWith(
      isAvailable: true,
      reason: option.reason.isNotEmpty
          ? option.reason
          : availability.reason,
    );
  }

  // Nếu server đã trả options → re-check từng cái, dùng server data làm gốc
  if (leg.transportOptions.isNotEmpty) {
    return leg.transportOptions.map(_recheck).toList();
  }

  // Không có server data → dùng fallback (đã chạy checkTransportAvailability)
  final fallback = _fallbackTransportOptionsForLeg(leg);
  return fallback.where((o) => o.isAvailable).toList();
}

/// Xác định origin thực sự của leg. Ưu tiên [RouteLeg.from] (Destination
/// object); nếu không có thì dùng [RouteLeg.to] làm fallback (khi đó
/// availability check sẽ giảm độ chính xác). Đừng để null ở đây.
Destination _originFor(RouteLeg leg) {
  return leg.from ??
      Destination(
        id: 'leg-${leg.order}-from',
        name: leg.fromName,
        region: '',
        latitude: 0,
        longitude: 0,
        landmassId: Destination.defaultLandmassFor(leg.fromName),
      );
}

List<TransportOption> _fallbackTransportOptionsForLeg(RouteLeg leg) {
  final recommendedMode = leg.recommendedMode;
  final distanceKm = leg.distanceKm;
  final currentReason = leg.reason.isEmpty
      ? 'Phương tiện hiện tại của chặng này.'
      : leg.reason;
  final origin = _originFor(leg);
  final dest = leg.to;

  // Dùng checkTransportAvailability() làm source of truth cho mọi mode.
  // Hàm này trả về {available, reason, journey?} dựa trên landmass +
  // hub proximity. Sau đó mới dùng journey để tính duration/cost.
  TransportOption opt(TransportMode mode, {bool? isRecommendedOverride}) {
    final availability = checkTransportAvailability(
      mode: mode, origin: origin, destination: dest,
    );
    final recommended = isRecommendedOverride ??
        (availability.available && recommendedMode == mode);
    final journey = availability.journey;
    return TransportOption(
      mode: mode,
      isAvailable: availability.available,
      isRecommended: recommended,
      reason: availability.available
          ? (recommended ? currentReason : availability.reason)
          : availability.reason,
      durationHours: journey?.totalDurationHours ?? _fallbackHours(distanceKm, mode),
      estimatedCostVnd: journey?.totalCostVnd ?? _fallbackCost(distanceKm, mode),
      segments: [
        leg.routeLabel,
        if (journey != null && journey.isMultiLeg)
          ...journey.legs.map((l) => l.note ?? '${l.fromLabel} -> ${l.toLabel}'),
      ],
    );
  }

  return [
    opt(TransportMode.car),
    opt(TransportMode.motorbike),
    opt(TransportMode.coach),
    opt(TransportMode.train),
    opt(TransportMode.flight),
    opt(TransportMode.ferry),
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
      // Phà cao tốc: 0.5h check-in + 30 km/h di chuyển trung bình (có dừng bến)
      return 0.5 + distanceKm / 30;
    case TransportMode.flight:
      return 2 + distanceKm / 650;
  }
}

double _fallbackCost(double distanceKm, TransportMode mode) {
  switch (mode) {
    case TransportMode.motorbike:
      // 900 VND/km là chi phí xăng; thực tế có thể 800-1200 VND/km
      return max(25000, distanceKm * 900);

    case TransportMode.car:
      // Grab/car: ~8.000-12.000 VND/km (tùy loại xe). Taxi: 11.000-15.000 VND/km
      // Thuê xe: 350.000-800.000/ngày ÷ ~200km/ngày = 1.750-4.000 VND/km
      // => Lấy trung bình 2.200 VND/km
      return max(100000, distanceKm * 2200);

    case TransportMode.coach:
      // Xe khách nội địa thuê nguyên xe: 550-900 VND/km (ghế ngồi/giường nằm)
      // Đây là giá THUÊ NGUYÊN XE, không phải giá vé 1 người
      return max(120000, distanceKm * 850);

    case TransportMode.train:
      // Tàu hỏa VN: 800-1.200 VND/km (ghế cứng → giường mềm)
      // Tàu Thống Nhất Hà Nội → TP.HCM: ~1.400 VND/km
      return max(160000, distanceKm * 1100);

    case TransportMode.ferry:
      // Phà cao tốc: phí cố định 350.000-500.000 VND cho hành khách
      // (đã bao gồm vé tàu, không tính riêng xe)
      return max(350000, distanceKm * 1200);

    case TransportMode.flight:
      // Giá vé máy bay nội địa VN (Vietjet, Bamboo, VietnamAirlines)
      // Đã bao gồm thuế, phí, suất mang hành lý cơ bản
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

// ─── Multi-leg journey ───────────────────────────────────────────────────────
//
// Đối với máy bay/phà: door-to-door journey bao gồm nhiều chặng. Ví dụ
// bay HCM → Phú Quốc:
//
//   1. Taxi từ HCM -> sân bay Tân Sơn Nhất          (~30 phút, ~66.000 đ)
//   2. Check-in + chờ tại sân bay                   (~1.5 giờ buffer)
//   3. Bay Tân Sơn Nhất -> Phú Quốc                (~1 giờ)
//   4. Taxi từ sân bay Phú Quốc -> destination       (~30 phút, ~33.000 đ)
//
// Mỗi sub-leg `JourneyLeg` có `mode` (TransportMode) và `subMode` (chi tiết
// cách đi – taxi/grab/xe riêng/xe khách). Sub-leg là 1 nguồn dữ liệu duy
// nhất cho UI: popup chọn phương tiện, _LegList, _SummaryCard đều đọc
// từ MultiLegJourney.

/// Phương tiện trung chuyển cụ thể cho sub-leg đường bộ (taxi/grab/xe riêng).
enum TransitSubMode {
  taxi,           // taxi truyền thống / Grab car
  privateCar,     // xe cá nhân / xe thuê
  shuttle,        // xe đưa đón sân bay (Airline shuttle)
  motorbike,      // xe ôm công nghệ (Grab bike)
  coach,          // xe buýt/trung chuyển liên tỉnh (>30km)

  /// Mode đã chọn không trung chuyển (vd đường bay, check-in).
  na,
}

extension TransitSubModeX on TransitSubMode {
  String get label {
    switch (this) {
      case TransitSubMode.taxi: return 'taxi/grab';
      case TransitSubMode.privateCar: return 'xe riêng';
      case TransitSubMode.shuttle: return 'shuttle sân bay';
      case TransitSubMode.motorbike: return 'xe ôm công nghệ';
      case TransitSubMode.coach: return 'xe khách trung chuyển';
      case TransitSubMode.na: return '';
    }
  }
}

class JourneyLeg {
  const JourneyLeg({
    required this.mode,
    required this.fromLabel,
    required this.toLabel,
    required this.distanceKm,
    required this.durationHours,
    required this.costVnd,
    this.note,
    this.subMode = TransitSubMode.na,
  });

  final TransportMode mode;
  final String fromLabel;
  final String toLabel;
  final double distanceKm;
  final double durationHours;
  final double costVnd;

  /// Ghi chú ngắn, ví dụ "Check-in & lên máy bay".
  final String? note;

  /// Phương tiện trung chuyển cụ thể cho sub-leg đường bộ. Vd `taxi`
  /// hiển thị thành "(taxi/grab)" trong UI. Với sub-leg đường bay/phà/
  /// check-in thì để `na`.
  final TransitSubMode subMode;

  String get durationLabel => formatHours(durationHours);
  String get costLabel => costVnd > 0 ? _formatCurrency(costVnd) : '';
}

class MultiLegJourney {
  const MultiLegJourney({
    required this.legs,
    required this.totalDurationHours,
    required this.totalCostVnd,
  });

  final List<JourneyLeg> legs;
  final double totalDurationHours;
  final double totalCostVnd;

  bool get isMultiLeg => legs.length > 1;
}

/// Chọn phương tiện trung chuyển đường bộ hợp lý theo khoảng cách + bối
/// cảnh (ra/vào sân bay, cảng). Quy tắc:
///   - ≤ 10 km & ra/vào sân bay/cảng → taxi/grab (phổ biến nhất)
///   - 10-30 km & cùng landmass xe cá nhân → xe riêng (nhanh hơn taxi)
///   - > 30 km & không có grab đường dài → xe khách trung chuyển nếu có
///   - đặc biệt nếu gần sân bay (≤3 km) → shuttle miễn phí
TransitSubMode _pickTransitSubMode({
  required double distanceKm,
  required bool isAirport,
  required bool isFerryPort,
}) {
  if (distanceKm < 1) return TransitSubMode.na;
  if (isAirport && distanceKm < 3) return TransitSubMode.shuttle;
  if (distanceKm <= 10) return TransitSubMode.taxi;
  if (distanceKm <= 30) return TransitSubMode.privateCar;
  // >30km thì hiếm khi đi taxi sân bay → chuyển sang xe khách/shuttle
  if (isAirport) return TransitSubMode.shuttle;
  if (isFerryPort) return TransitSubMode.privateCar;
  return TransitSubMode.coach;
}

/// Inline formatter VND (vì library `route_analysis` không được import
/// `BudgetTier` – giữ cho lib pure-Dart). Format kiểu "1.250.000 đ".
String _formatCurrency(double vnd) {
  if (vnd <= 0) return '';
  final n = vnd.round();
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '$buf đ';
}

// ─── checkTransportAvailability ────────────────────────────────────────────────
//
// Trả về {available, reason} cho mọi mode dựa trên:
//   - landmass (xe máy/ô tô/xe khách cần cùng landmass; nếu khác → đảo)
//   - khoảng cách (xe khách < 40km thì không hợp lý; xe máy > 180km thì không)
//   - hub gần nhất: tàu hỏa cần 2 ga, máy bay cần 2 sân bay, phà cần 2 cảng
//
// Hàm này không phụ thuộc leg.distanceKm đã có sẵn – luôn dùng Haversine
// từ Destination.latitude/longitude để có số liệu chuẩn.

class TransportAvailability {
  const TransportAvailability({
    required this.available,
    required this.reason,
    this.journey,
  });
  final bool available;
  final String reason;

  /// Multi-leg breakdown nếu mode có (flight/ferry). Với car/motorbike/coach
  /// thì journey là 1-chặng đơn giản, nhưng để đồng nhất vẫn set luôn.
  final MultiLegJourney? journey;
}

/// LandmassId dùng nội bộ – map từ String sang enum [LandmassId].
LandmassId _landmassFromString(String s) {
  switch (s) {
    case 'phuQuoc': return LandmassId.phuQuoc;
    case 'conDao': return LandmassId.conDao;
    case 'smallIsland': return LandmassId.smallIsland;
    default: return LandmassId.mainland;
  }
}

/// Khoảng cách Haversine giữa 2 toạ độ (km).
double _haversineKm(Destination a, Destination b) {
  return _hubDistanceKm(a.latitude, a.longitude, b.latitude, b.longitude);
}

/// Build single-leg journey (dùng cho mọi mode road-based + train). Với
/// road-based, distanceKm = thẳng đường bay, thời gian = distanceKm / tốc
/// độ trung bình.
MultiLegJourney _buildSingleLegJourney({
  required TransportMode mode,
  required String fromLabel,
  required String toLabel,
  required double distanceKm,
}) {
  final hours = _fallbackHours(distanceKm, mode);
  final cost = _fallbackCost(distanceKm, mode);
  return MultiLegJourney(
    legs: [
      JourneyLeg(
        mode: mode,
        fromLabel: fromLabel,
        toLabel: toLabel,
        distanceKm: distanceKm,
        durationHours: hours,
        costVnd: cost,
      ),
    ],
    totalDurationHours: hours,
    totalCostVnd: cost,
  );
}

/// Door-to-door journey cho máy bay: taxi → sân bay → check-in → bay →
/// sân bay → taxi.
MultiLegJourney _buildFlightJourney({
  required Destination origin,
  required Destination destination,
  required _NearestHub originHub,
  required _NearestHub destHub,
  required double flightKm,
}) {
  final originIsHub = originHub.distanceKm < 1;
  final destIsHub = destHub.distanceKm < 1;
  final legs = <JourneyLeg>[];

  // 1. Taxi/xe riêng từ origin → sân bay khởi hành
  if (!originIsHub) {
    final sub = _pickTransitSubMode(
      distanceKm: originHub.distanceKm,
      isAirport: true,
      isFerryPort: false,
    );
    legs.add(JourneyLeg(
      mode: TransportMode.car,
      fromLabel: origin.name,
      toLabel: 'Sân bay ${originHub.hub.name}',
      distanceKm: originHub.distanceKm,
      durationHours: originHub.distanceKm / 45,
      costVnd: _fallbackCost(originHub.distanceKm, TransportMode.car),
      note: 'Di chuyển ra sân bay',
      subMode: sub,
    ));
  }

  // 2. Check-in + chờ boarding (~1.5 giờ buffer)
  legs.add(JourneyLeg(
    mode: TransportMode.flight,
    fromLabel: originHub.hub.name,
    toLabel: destHub.hub.name,
    distanceKm: flightKm,
    durationHours: 1.5,
    costVnd: 0,
    note: 'Check-in, soi chiếu, lên máy bay',
    subMode: TransitSubMode.na,
  ));

  // 3. Bay thẳng (~750 km/h + taxi/runway)
  final flightHours = 1.0 + flightKm / 750;
  legs.add(JourneyLeg(
    mode: TransportMode.flight,
    fromLabel: originHub.hub.name,
    toLabel: destHub.hub.name,
    distanceKm: flightKm,
    durationHours: flightHours,
    costVnd: _fallbackCost(flightKm, TransportMode.flight),
    note: 'Bay thẳng',
    subMode: TransitSubMode.na,
  ));

  // 4. Taxi/xe riêng từ sân bay đến → destination
  if (!destIsHub) {
    final sub = _pickTransitSubMode(
      distanceKm: destHub.distanceKm,
      isAirport: true,
      isFerryPort: false,
    );
    legs.add(JourneyLeg(
      mode: TransportMode.car,
      fromLabel: 'Sân bay ${destHub.hub.name}',
      toLabel: destination.name,
      distanceKm: destHub.distanceKm,
      durationHours: destHub.distanceKm / 45,
      costVnd: _fallbackCost(destHub.distanceKm, TransportMode.car),
      note: 'Di chuyển về điểm đến',
      subMode: sub,
    ));
  }

  return MultiLegJourney(
    legs: legs,
    totalDurationHours: legs.fold(0, (s, l) => s + l.durationHours),
    totalCostVnd: legs.fold(0, (s, l) => s + l.costVnd),
  );
}

/// Door-to-door journey cho phà: taxi → cảng → check-in → phà → cảng → taxi.
MultiLegJourney _buildFerryJourney({
  required Destination origin,
  required Destination destination,
  required _NearestHub originHub,
  required _NearestHub destHub,
  required double ferryKm,
}) {
  final originIsHub = originHub.distanceKm < 1;
  final destIsHub = destHub.distanceKm < 1;
  final legs = <JourneyLeg>[];

  // 1. Taxi/xe riêng ra cảng
  if (!originIsHub) {
    final sub = _pickTransitSubMode(
      distanceKm: originHub.distanceKm,
      isAirport: false,
      isFerryPort: true,
    );
    legs.add(JourneyLeg(
      mode: TransportMode.car,
      fromLabel: origin.name,
      toLabel: 'Cảng ${originHub.hub.name}',
      distanceKm: originHub.distanceKm,
      durationHours: originHub.distanceKm / 40,
      costVnd: _fallbackCost(originHub.distanceKm, TransportMode.car),
      note: 'Di chuyển ra cảng',
      subMode: sub,
    ));
  }

  // 2. Check-in + chờ (~30-45p)
  legs.add(JourneyLeg(
    mode: TransportMode.ferry,
    fromLabel: originHub.hub.name,
    toLabel: destHub.hub.name,
    distanceKm: 0,
    durationHours: 0.5,
    costVnd: 0,
    note: 'Check-in, xếp vé, lên tàu',
    subMode: TransitSubMode.na,
  ));

  // 3. Phà thực sự
  final ferryHours = 1.0 + ferryKm / 30;
  legs.add(JourneyLeg(
    mode: TransportMode.ferry,
    fromLabel: originHub.hub.name,
    toLabel: destHub.hub.name,
    distanceKm: ferryKm,
    durationHours: ferryHours,
    costVnd: _fallbackCost(ferryKm, TransportMode.ferry),
    note: 'Hành trình phà/tàu cao tốc',
    subMode: TransitSubMode.na,
  ));

  // 4. Taxi/xe riêng từ cảng → destination
  if (!destIsHub) {
    final sub = _pickTransitSubMode(
      distanceKm: destHub.distanceKm,
      isAirport: false,
      isFerryPort: true,
    );
    legs.add(JourneyLeg(
      mode: TransportMode.car,
      fromLabel: 'Cảng ${destHub.hub.name}',
      toLabel: destination.name,
      distanceKm: destHub.distanceKm,
      durationHours: destHub.distanceKm / 40,
      costVnd: _fallbackCost(destHub.distanceKm, TransportMode.car),
      note: 'Di chuyển về điểm đến',
      subMode: sub,
    ));
  }

  return MultiLegJourney(
    legs: legs,
    totalDurationHours: legs.fold(0, (s, l) => s + l.durationHours),
    totalCostVnd: legs.fold(0, (s, l) => s + l.costVnd),
  );
}

/// Build door-to-door journey cho 1 mode cụ thể (nếu mode có multi-leg).
MultiLegJourney? buildMultiLegJourney({
  required TransportMode mode,
  required Destination origin,
  required Destination destination,
}) {
  final km = _haversineKm(origin, destination);

  switch (mode) {
    case TransportMode.motorbike:
    case TransportMode.car:
    case TransportMode.coach:
    case TransportMode.train:
      return _buildSingleLegJourney(
        mode: mode,
        fromLabel: origin.name,
        toLabel: destination.name,
        distanceKm: km,
      );

    case TransportMode.flight:
      final o = _nearestAirport(origin.latitude, origin.longitude);
      final d = _nearestAirport(destination.latitude, destination.longitude);
      if (o == null || d == null) return null;
      return _buildFlightJourney(
        origin: origin,
        destination: destination,
        originHub: o,
        destHub: d,
        flightKm: km,
      );

    case TransportMode.ferry:
      final o = _nearestFerryPort(origin.latitude, origin.longitude);
      final d = _nearestFerryPort(destination.latitude, destination.longitude);
      if (o == null || d == null) return null;
      return _buildFerryJourney(
        origin: origin,
        destination: destination,
        originHub: o,
        destHub: d,
        ferryKm: km,
      );
  }
}

/// Build journey breakdown cho 1 [RouteLeg] dựa trên `recommendedMode`.
/// Đây là **single source of truth** cho toàn bộ UI (popup, _LegList,
/// _SummaryCard).
///
/// Trả về `null` nếu leg không có `from`/`to` hợp lệ.
MultiLegJourney? effectiveJourneyForLeg(RouteLeg leg) {
  final origin = leg.from;
  final dest = leg.to;
  if (origin == null) return null;
  if (origin.latitude == 0 && origin.longitude == 0) {
    // Origin không có toạ độ thật → không tính được multi-leg.
    return null;
  }
  return buildMultiLegJourney(
    mode: leg.recommendedMode, origin: origin, destination: dest,
  );
}

// ─── API chính: checkTransportAvailability ────────────────────────────────────

TransportAvailability checkTransportAvailability({
  required TransportMode mode,
  required Destination origin,
  required Destination destination,
}) {
  final km = _haversineKm(origin, destination);
  final originLandmass = _landmassFromString(origin.landmassIdOrDefault);
  final destLandmass = _landmassFromString(destination.landmassIdOrDefault);
  final sameLandmass = originLandmass == destLandmass;
  final landReason = 'Origin và destination ở hai vùng đất khác nhau '
      '(${originLandmass.name} ↔ ${destLandmass.name}), phương tiện này không nối được.';

  switch (mode) {
    case TransportMode.motorbike:
      if (!sameLandmass) {
        return TransportAvailability(
          available: false,
          reason: landReason,
        );
      }
      if (km > 180) {
        return TransportAvailability(
          available: false,
          reason: 'Quãng đường ${km.toStringAsFixed(0)} km quá dài cho xe máy (tối đa 180 km).',
        );
      }
      return TransportAvailability(
        available: true,
        reason: 'Phù hợp cho chặng ngắn dưới 180 km.',
        journey: buildMultiLegJourney(
          mode: mode, origin: origin, destination: destination,
        ),
      );

    case TransportMode.car:
      if (!sameLandmass) {
        return TransportAvailability(
          available: false,
          reason: landReason,
        );
      }
      return TransportAvailability(
        available: true,
        reason: 'Có thể đi bằng ô tô/taxi trên đường bộ.',
        journey: buildMultiLegJourney(
          mode: mode, origin: origin, destination: destination,
        ),
      );

    case TransportMode.coach:
      if (!sameLandmass) {
        return TransportAvailability(
          available: false,
          reason: landReason,
        );
      }
      if (km < 40) {
        return TransportAvailability(
          available: false,
          reason: 'Chặng ngắn dưới 40 km, xe khách thường không có tuyến phù hợp.',
        );
      }
      return TransportAvailability(
        available: true,
        reason: 'Xe khách phù hợp chặng liên tỉnh từ 40 km trở lên.',
        journey: buildMultiLegJourney(
          mode: mode, origin: origin, destination: destination,
        ),
      );

    case TransportMode.train:
      if (!sameLandmass) {
        return TransportAvailability(
          available: false,
          reason: landReason,
        );
      }
      final o = _nearestTrainStation(origin.latitude, origin.longitude);
      final d = _nearestTrainStation(destination.latitude, destination.longitude);
      if (o == null) {
        return TransportAvailability(
          available: false,
          reason: 'Không có ga tàu hỏa trong bán kính 30 km từ "${origin.name}".',
        );
      }
      if (d == null) {
        return TransportAvailability(
          available: false,
          reason: 'Không có ga tàu hỏa trong bán kính 30 km từ "${destination.name}".',
        );
      }
      if (km < 80) {
        return TransportAvailability(
          available: false,
          reason: 'Chặng ngắn dưới 80 km, tàu hỏa không có tuyến phù hợp.',
        );
      }
      if (km > 1800) {
        return TransportAvailability(
          available: false,
          reason: 'Chặng ${km.toStringAsFixed(0)} km quá dài, nên chọn máy bay.',
        );
      }
      return TransportAvailability(
        available: true,
        reason: 'Có thể đi tàu hỏa: ga ${o.hub.name} → ga ${d.hub.name}.',
        journey: buildMultiLegJourney(
          mode: mode, origin: origin, destination: destination,
        ),
      );

    case TransportMode.flight:
      final o = _nearestAirport(origin.latitude, origin.longitude);
      final d = _nearestAirport(destination.latitude, destination.longitude);
      if (o == null) {
        return TransportAvailability(
          available: false,
          reason: 'Không có sân bay trong bán kính ${_airportCatchRadiusKm.toStringAsFixed(0)} km từ "${origin.name}".',
        );
      }
      if (d == null) {
        return TransportAvailability(
          available: false,
          reason: 'Không có sân bay trong bán kính ${_airportCatchRadiusKm.toStringAsFixed(0)} km từ "${destination.name}".',
        );
      }
      if (o.hub.landmass == d.hub.landmass && km < 350) {
        return TransportAvailability(
          available: false,
          reason: 'Hai sân bay chỉ cách ${km.toStringAsFixed(0)} km, thường không có chuyến bay thường lệ.',
        );
      }
      return TransportAvailability(
        available: true,
        reason: 'Có chuyến bay thẳng: ${o.hub.name} → ${d.hub.name}.',
        journey: buildMultiLegJourney(
          mode: mode, origin: origin, destination: destination,
        ),
      );

    case TransportMode.ferry:
      final o = _nearestFerryPort(origin.latitude, origin.longitude);
      final d = _nearestFerryPort(destination.latitude, destination.longitude);
      if (o == null) {
        return TransportAvailability(
          available: false,
          reason: 'Không có bến cảng trong bán kính ${_ferryPortCatchRadiusKm.toStringAsFixed(0)} km từ "${origin.name}".',
        );
      }
      if (d == null) {
        return TransportAvailability(
          available: false,
          reason: 'Không có bến cảng trong bán kính ${_ferryPortCatchRadiusKm.toStringAsFixed(0)} km từ "${destination.name}".',
        );
      }
      if (o.hub.landmass == d.hub.landmass) {
        return TransportAvailability(
          available: false,
          reason: 'Hai bến cảng cùng vùng đất (${o.hub.landmass.name}), nên đi đường bộ sẽ thuận tiện hơn.',
        );
      }
      return TransportAvailability(
        available: true,
        reason: 'Có tuyến phà: ${o.hub.name} → ${d.hub.name}.',
        journey: buildMultiLegJourney(
          mode: mode, origin: origin, destination: destination,
        ),
      );
  }
}
