class Destination {
  const Destination({
    required this.id,
    required this.name,
    required this.region,
    required this.latitude,
    required this.longitude,
    this.highlight = '',
    this.distanceFromPreviousKm = 0,
    this.landmassId,
  });

  final String id;
  final String name;
  final String region;
  final double latitude;
  final double longitude;
  final String highlight;
  final double distanceFromPreviousKm;
  /// Vùng đất của điểm này. Nếu null sẽ tự detect qua [name] (xem
  /// [landmassIdOrDefault]).
  final String? landmassId;

  /// Landmass resolve từ field hoặc tự detect theo tên.
  String get landmassIdOrDefault =>
      landmassId ?? Destination.defaultLandmassFor(name);

  Destination copyWith({
    String? id,
    String? name,
    String? region,
    double? latitude,
    double? longitude,
    String? highlight,
    double? distanceFromPreviousKm,
    String? landmassId,
  }) {
    return Destination(
      id: id ?? this.id,
      name: name ?? this.name,
      region: region ?? this.region,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      highlight: highlight ?? this.highlight,
      distanceFromPreviousKm:
          distanceFromPreviousKm ?? this.distanceFromPreviousKm,
      landmassId: landmassId ?? this.landmassId,
    );
  }

  Destination copyWithName(String value) => copyWith(name: value);

  /// Heuristic landmass detection theo tên. Kết quả dùng được cho
  /// route analysis – nếu cần độ chính xác cao hơn, đặt [landmassId] từ API.
  static String defaultLandmassFor(String name) {
    final lower = name.toLowerCase().trim();
    if (lower.isEmpty) return 'mainland';
    if (lower.contains('phú quốc') || lower.contains('phu quoc')) {
      return 'phuQuoc';
    }
    if (lower.contains('côn đảo') || lower.contains('con dao')) {
      return 'conDao';
    }
    const smallIslands = [
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
    for (final s in smallIslands) {
      if (lower.contains(s)) return 'smallIsland';
    }
    return 'mainland';
  }

  /// Whether this destination is an island that can only be reached by
  /// ferry or flight (no road connection to the mainland).
  bool get isIsland => Destination.isIslandName(name);

  /// Heuristic island detection based on the place name.
  /// Covers well-known Vietnamese islands (Phú Quốc, Côn Đảo, Cát Bà…)
  /// and the common "Đảo / Hòn / Cù Lao" prefixes.
  static bool isIslandName(String name) {
    final lower = name.toLowerCase().trim();
    if (lower.isEmpty) return false;
    if (lower.startsWith('đảo ') || lower.startsWith('dao ')) return true;
    if (lower.startsWith('hòn ') || lower.startsWith('hon ')) return true;
    if (lower.startsWith('cù lao ') || lower.startsWith('cu lao ')) return true;
    return _islandNames.contains(lower);
  }

  /// Whether this destination is a coastal city with ferry/port access.
  bool get isCoastalCity => Destination.isCoastalCityName(name);

  /// Heuristic coastal city detection based on the place name.
  /// Covers major Vietnamese coastal cities and port cities.
  static bool isCoastalCityName(String name) {
    final lower = name.toLowerCase().trim();
    if (lower.isEmpty) return false;
    return _coastalCityNames.contains(lower);
  }

  static const Set<String> _islandNames = {
    'phú quốc', 'phu quoc',
    'côn đảo', 'con dao',
    'cát bà', 'cat ba',
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
  };

  static const Set<String> _coastalCityNames = {
    // Bắc Bộ
    'hải phòng', 'hai phong',
    'hạ long', 'ha long', 'quảng ninh', 'quang ninh',
    // Bắc Trung Bộ
    'thanh hóa', 'thanh hoa',
    'nghệ an', 'nghe an', 'vinh',
    'hà tĩnh', 'ha tinh',
    'quảng bình', 'quang binh', 'đồng hới', 'dong hoi',
    'quảng trị', 'quang tri', 'đông hà', 'dong ha',
    'thừa thiên huế', 'thua thien hue', 'huế', 'hue',
    'đà nẵng', 'da nang',
    // Nam Trung Bộ
    'quảng nam', 'quang nam', 'hội an', 'hoi an',
    'quảng ngãi', 'quang ngai',
    'bình định', 'binh dinh', 'quy nhơn', 'quy nhon',
    'phú yên', 'phu yen', 'tuy hòa', 'tuy hoa',
    'khánh hòa', 'khanh hoa', 'nha trang', 'cam ranh',
    // Tây Nguyên (không ven biển - skip)
    // Nam Bộ
    'bình thuận', 'binh thuan', 'phan thiết', 'phan thiet',
    'bà rịa vũng tàu', 'ba ria vung tau', 'vũng tàu', 'vung tau',
    'hồ chí minh', 'ho chi minh', 'tp.hcm', 'tp hcm', 'sài gòn', 'sai gon',
    // Đồng bằng sông Cửu Long
    'cần thơ', 'can tho',
    'sóc trăng', 'soc trang',
    'bạc liêu', 'bac lieu',
    'cà mau', 'ca mau',
    'tiền giang', 'tien giang', 'mỹ tho', 'my tho',
    'bến tre', 'ben tre',
    'trà vinh', 'tra vinh',
    'vĩnh long', 'vinh long',
    'đồng tháp', 'dong thap', 'cao lãnh', 'cao lanh',
    'an giang', 'long xuyên', 'long xuyen',
    'kiên giang', 'kien giang', 'rạch giá', 'rach gia',
    'hậu giang', 'hau giang',
  };
}

class SelectedDestination {
  const SelectedDestination({
    required this.destination,
    required this.fromLabel,
    required this.distanceKm,
    this.startDate,
    this.endDate,
  });

  final Destination destination;
  final String fromLabel;
  final double distanceKm;
  final DateTime? startDate;
  final DateTime? endDate;

  String get subtitleLabel {
    if (distanceKm <= 0) return 'Tinh tu $fromLabel';
    return '${distanceKm.toStringAsFixed(0)} km tu $fromLabel';
  }

  SelectedDestination copyWith({
    Destination? destination,
    String? fromLabel,
    double? distanceKm,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return SelectedDestination(
      destination: destination ?? this.destination,
      fromLabel: fromLabel ?? this.fromLabel,
      distanceKm: distanceKm ?? this.distanceKm,
      startDate: clearStartDate ? null : startDate ?? this.startDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
    );
  }
}
