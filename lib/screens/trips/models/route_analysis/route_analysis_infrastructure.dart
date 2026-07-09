// ignore_for_file: use_string_in_part_of_directives
//
// Cơ sở dữ liệu hạ tầng giao thông Việt Nam cho route analysis:
//   - Sân bay có chuyến bay thường lệ
//   - Bến cảng có tuyến phà/tàu cao tốc
//   - Ga tàu hỏa liên tỉnh
//   - LandmassId cho mỗi hub (để check road-connected)
//
// Các const list được khai báo compile-time → không tốn runtime, có thể
// truy cập nhanh từ checkTransportAvailability/buildMultiLegJourney.

part of route_analysis;

/// Phân loại vùng đất. Hai điểm có cùng [LandmassId] thì được coi là có
/// thể đi bằng đường bộ giữa chúng (xe máy/ô tô/xe khách).
enum LandmassId {
  /// Đất liền Việt Nam + các đảo ven bờ có cầu/đường nối (Cát Bà,
  /// Cù Lao Chàm nhỏ, v.v.).
  mainland,

  /// Phú Quốc – đảo lớn ở Tây Nam, chỉ tới được bằng máy bay hoặc phà.
  phuQuoc,

  /// Côn Đảo – huyện đảo ngoài khơi Bà Rịa-Vũng Tàu, chỉ tới được bằng
  /// máy bay hoặc phà.
  conDao,

  /// Quần đảo nhỏ khác (Lý Sơn, Phú Quý, Nam Du...) – chỉ tới bằng tàu.
  smallIsland,
}

/// Hub (sân bay / cảng / ga tàu) có toạ độ thực.
class TransportHub {
  const TransportHub({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.landmass,
    this.kind = TransportHubKind.airport,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final LandmassId landmass;
  final TransportHubKind kind;
}

enum TransportHubKind { airport, ferryPort, trainStation }

// ─── Sân bay có chuyến bay thường lệ ──────────────────────────────────────────
// Lấy từ CAAV + Vietnam Airlines/Vietjet/Bamboo network. Toạ độ WGS84 xấp xỉ.
const List<TransportHub> _airports = [
  // Miền Bắc
  TransportHub(id: 'HAN', name: 'Nội Bài (Hà Nội)',
      latitude: 21.2187, longitude: 105.8072, landmass: LandmassId.mainland),
  TransportHub(id: 'HPH', name: 'Cát Bi (Hải Phòng)',
      latitude: 20.8194, longitude: 106.7249, landmass: LandmassId.mainland),
  TransportHub(id: 'VII', name: 'Vinh',
      latitude: 18.7375, longitude: 105.6717, landmass: LandmassId.mainland),
  // Miền Trung
  TransportHub(id: 'THD', name: 'Thọ Xuân (Thanh Hóa)',
      latitude: 19.9017, longitude: 105.4681, landmass: LandmassId.mainland),
  TransportHub(id: 'HUI', name: 'Phú Bài (Huế)',
      latitude: 16.4015, longitude: 107.7026, landmass: LandmassId.mainland),
  TransportHub(id: 'DAD', name: 'Đà Nẵng',
      latitude: 16.0439, longitude: 108.1994, landmass: LandmassId.mainland),
  TransportHub(id: 'VCL', name: 'Chu Lai (Quảng Nam)',
      latitude: 15.4063, longitude: 108.7057, landmass: LandmassId.mainland),
  TransportHub(id: 'UIH', name: 'Phù Cát (Quy Nhơn)',
      latitude: 13.9545, longitude: 109.0420, landmass: LandmassId.mainland),
  TransportHub(id: 'TBB', name: 'Tuy Hòa (Phú Yên)',
      latitude: 13.0495, longitude: 109.3337, landmass: LandmassId.mainland),
  TransportHub(id: 'CXR', name: 'Cam Ranh (Khánh Hòa)',
      latitude: 11.9981, longitude: 109.2192, landmass: LandmassId.mainland),
  // Tây Nguyên
  TransportHub(id: 'BMV', name: 'Buôn Ma Thuột',
      latitude: 12.6683, longitude: 108.1203, landmass: LandmassId.mainland),
  TransportHub(id: 'DLI', name: 'Liên Khương (Đà Lạt)',
      latitude: 11.7506, longitude: 108.3666, landmass: LandmassId.mainland),
  // Miền Nam
  TransportHub(id: 'SGN', name: 'Tân Sơn Nhất (TP.HCM)',
      latitude: 10.8188, longitude: 106.6519, landmass: LandmassId.mainland),
  TransportHub(id: 'VCA', name: 'Cần Thơ',
      latitude: 10.0851, longitude: 105.7117, landmass: LandmassId.mainland),
  TransportHub(id: 'VCS', name: 'Côn Đảo',
      latitude: 8.7317, longitude: 106.6328, landmass: LandmassId.conDao),
  // Đảo
  TransportHub(id: 'PQC', name: 'Phú Quốc',
      latitude: 10.1700, longitude: 103.9931, landmass: LandmassId.phuQuoc),
];

// ─── Bến cảng có tuyến phà/tàu cao tốc ────────────────────────────────────────
// Toạ độ xấp xỉ các bến cảng chính.
const List<TransportHub> _ferryPorts = [
  // Đất liền gần Phú Quốc
  TransportHub(id: 'PORT_RG', name: 'Rạch Giá',
      latitude: 9.9937, longitude: 105.0839, landmass: LandmassId.mainland,
      kind: TransportHubKind.ferryPort),
  TransportHub(id: 'PORT_HT', name: 'Hà Tiên',
      latitude: 10.3872, longitude: 104.4878, landmass: LandmassId.mainland,
      kind: TransportHubKind.ferryPort),
  // Đảo
  TransportHub(id: 'PORT_PQ', name: 'Bãi Vòng (Phú Quốc)',
      latitude: 10.0803, longitude: 104.3603, landmass: LandmassId.phuQuoc,
      kind: TransportHubKind.ferryPort),
  // Đất liền gần Côn Đảo
  TransportHub(id: 'PORT_VT', name: 'Vũng Tàu (Cầu Đá)',
      latitude: 10.3624, longitude: 107.0803, landmass: LandmassId.mainland,
      kind: TransportHubKind.ferryPort),
  TransportHub(id: 'PORT_TTCAU', name: 'Trần Đề (Sóc Trăng)',
      latitude: 9.5028, longitude: 106.1169, landmass: LandmassId.mainland,
      kind: TransportHubKind.ferryPort),
  TransportHub(id: 'PORT_CD', name: 'Bến Đầm (Côn Đảo)',
      latitude: 8.6831, longitude: 106.6133, landmass: LandmassId.conDao,
      kind: TransportHubKind.ferryPort),
  // Đảo nhỏ miền Trung
  TransportHub(id: 'PORT_LS', name: 'Lý Sơn',
      latitude: 15.3831, longitude: 109.1528, landmass: LandmassId.smallIsland,
      kind: TransportHubKind.ferryPort),
  TransportHub(id: 'PORT_SA', name: 'Sa Kỳ (Quảng Ngãi)',
      latitude: 15.2539, longitude: 108.7708, landmass: LandmassId.mainland,
      kind: TransportHubKind.ferryPort),
  // Cát Bà - có cầu/đường từ Hải Phòng nên landmass = mainland
  TransportHub(id: 'PORT_CB', name: 'Cát Bà',
      latitude: 20.7269, longitude: 107.0489, landmass: LandmassId.mainland,
      kind: TransportHubKind.ferryPort),
];

// ─── Ga tàu hỏa liên tỉnh ────────────────────────────────────────────────────
// Chỉ các ga có tuyến khách liên tỉnh Bắc-Nam + một số nhánh.
const List<TransportHub> _trainStations = [
  TransportHub(id: 'STA_HN', name: 'Hà Nội',
      latitude: 21.0267, longitude: 105.8342, landmass: LandmassId.mainland,
      kind: TransportHubKind.trainStation),
  TransportHub(id: 'STA_NB', name: 'Nam Định',
      latitude: 20.4202, longitude: 106.1683, landmass: LandmassId.mainland,
      kind: TransportHubKind.trainStation),
  TransportHub(id: 'STA_HP', name: 'Hải Phòng',
      latitude: 20.8449, longitude: 106.6881, landmass: LandmassId.mainland,
      kind: TransportHubKind.trainStation),
  TransportHub(id: 'STA_TH', name: 'Thanh Hóa',
      latitude: 19.8042, longitude: 105.7831, landmass: LandmassId.mainland,
      kind: TransportHubKind.trainStation),
  TransportHub(id: 'STA_VINH', name: 'Vinh',
      latitude: 18.6796, longitude: 105.6814, landmass: LandmassId.mainland,
      kind: TransportHubKind.trainStation),
  TransportHub(id: 'STA_HUE', name: 'Huế',
      latitude: 16.4637, longitude: 107.5909, landmass: LandmassId.mainland,
      kind: TransportHubKind.trainStation),
  TransportHub(id: 'STA_DN', name: 'Đà Nẵng',
      latitude: 16.0728, longitude: 108.2133, landmass: LandmassId.mainland,
      kind: TransportHubKind.trainStation),
  TransportHub(id: 'STA_NT', name: 'Nha Trang',
      latitude: 12.2513, longitude: 109.1830, landmass: LandmassId.mainland,
      kind: TransportHubKind.trainStation),
  TransportHub(id: 'STA_TT', name: 'Tháp Chàm (Ninh Thuận)',
      latitude: 11.5667, longitude: 108.9833, landmass: LandmassId.mainland,
      kind: TransportHubKind.trainStation),
  TransportHub(id: 'STA_SG', name: 'Sài Gòn',
      latitude: 10.7853, longitude: 106.6492, landmass: LandmassId.mainland,
      kind: TransportHubKind.trainStation),
];

// ─── Bán kính khả thi ─────────────────────────────────────────────────────────
// Khoảng cách tối đa từ origin/destination đến hub tương ứng. Vượt quá coi
// như "không có hub phù hợp" → disable mode đó.
const double _airportCatchRadiusKm = 150;
const double _ferryPortCatchRadiusKm = 80;
const double _trainStationCatchRadiusKm = 30;

// ─── API truy vấn hub ────────────────────────────────────────────────────────

/// Tìm hub gần nhất với [point] trong [hubs] thỏa mãn `distance ≤ maxRadiusKm`.
/// Trả về null nếu không có hub nào trong bán kính.
class _NearestHub {
  const _NearestHub(this.hub, this.distanceKm);
  final TransportHub hub;
  final double distanceKm;
}

_NearestHub? _findNearestHub(
  List<TransportHub> hubs,
  double lat,
  double lng, {
  double maxRadiusKm = 100,
  LandmassId? requiredLandmass,
}) {
  _NearestHub? best;
  for (final hub in hubs) {
    if (requiredLandmass != null && hub.landmass != requiredLandmass) continue;
    final d = _hubDistanceKm(lat, lng, hub.latitude, hub.longitude);
    if (d > maxRadiusKm) continue;
    if (best == null || d < best.distanceKm) best = _NearestHub(hub, d);
  }
  return best;
}

double _hubDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  const radius = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);
  return radius * 2 * atan2(sqrt(a), sqrt(1 - a));
}

// ─── Lookup public ────────────────────────────────────────────────────────────

_NearestHub? _nearestAirport(double lat, double lng) =>
    _findNearestHub(_airports, lat, lng,
        maxRadiusKm: _airportCatchRadiusKm);

_NearestHub? _nearestFerryPort(double lat, double lng) =>
    _findNearestHub(_ferryPorts, lat, lng,
        maxRadiusKm: _ferryPortCatchRadiusKm);

_NearestHub? _nearestTrainStation(double lat, double lng) =>
    _findNearestHub(_trainStations, lat, lng,
        maxRadiusKm: _trainStationCatchRadiusKm);

// ─── Landmass detection cho Destination ───────────────────────────────────────

/// Xác định landmass dựa vào tên. Mặc định [LandmassId.mainland] cho
/// các điểm không nằm trong danh sách đặc biệt.
LandmassId landmassOfName(String name) {
  final lower = name.toLowerCase().trim();
  if (lower.isEmpty) return LandmassId.mainland;
  // Phú Quốc + hòn nhỏ thuộc Phú Quốc
  if (lower.contains('phú quốc') || lower.contains('phu quoc')) {
    return LandmassId.phuQuoc;
  }
  // Côn Đảo
  if (lower.contains('côn đảo') || lower.contains('con dao')) {
    return LandmassId.conDao;
  }
  // Đảo nhỏ khác (Lý Sơn, Phú Quý, Nam Du, Cù Lao Chàm, Bình Hưng, Bình Ba,
  // Cô Tô, Quan Lạn, Minh Châu, Ngọc Vừng)
  const smallIslandNames = [
    'lý sơn', 'ly son',
    'phú quý', 'phu quy',
    'nam du',
    'cù lao chàm', 'cu lao cham',
    'bình hưng', 'binh hung',
    'bình ba', 'binh ba',
    'cô tô', 'co to',
    'quan lạn', 'quan lan',
    'minh châu', 'minh chau',
    'ngọc vừng', 'ngoc vung',
  ];
  for (final s in smallIslandNames) {
    if (lower.contains(s)) return LandmassId.smallIsland;
  }
  // Các đảo có cầu/đường nối → vẫn coi là mainland
  // (Cát Bà, Cù Lao Ré, Thới Sơn, v.v. đã có cầu).
  return LandmassId.mainland;
}