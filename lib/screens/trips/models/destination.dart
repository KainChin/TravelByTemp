class Destination {
  const Destination({
    required this.id,
    required this.name,
    required this.region,
    required this.latitude,
    required this.longitude,
    this.highlight = '',
    this.distanceFromPreviousKm = 0,
  });

  final String id;
  final String name;
  final String region;
  final double latitude;
  final double longitude;
  final String highlight;
  final double distanceFromPreviousKm;

  Destination copyWith({
    String? id,
    String? name,
    String? region,
    double? latitude,
    double? longitude,
    String? highlight,
    double? distanceFromPreviousKm,
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
    );
  }

  Destination copyWithName(String value) => copyWith(name: value);
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
    if (distanceKm <= 0) return 'Tính từ $fromLabel';
    return '${distanceKm.toStringAsFixed(0)} km từ $fromLabel';
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

class DestinationCatalog {
  static const Destination hoChiMinh = Destination(
    id: 'ho_chi_minh',
    name: 'Hồ Chí Minh',
    region: 'Miền Nam',
    latitude: 10.7769,
    longitude: 106.7009,
    highlight: 'Landmark 81, phố đi bộ Nguyễn Huệ',
  );

  static const Map<String, List<Destination>> byRegion = {
    'Miền Tây': [
      Destination(id: 'long_an', name: 'Long An', region: 'Miền Tây', latitude: 10.6956, longitude: 106.2431, highlight: 'Làng nổi Tân Lập'),
      Destination(id: 'tien_giang', name: 'Tiền Giang', region: 'Miền Tây', latitude: 10.4493, longitude: 106.3421, highlight: 'Mỹ Tho, cù lao Thới Sơn'),
      Destination(id: 'ben_tre', name: 'Bến Tre', region: 'Miền Tây', latitude: 10.2434, longitude: 106.3756, highlight: 'Miệt vườn, xứ dừa'),
      Destination(id: 'vinh_long', name: 'Vĩnh Long', region: 'Miền Tây', latitude: 10.2537, longitude: 105.9722, highlight: 'Cù lao An Bình'),
      Destination(id: 'tra_vinh', name: 'Trà Vinh', region: 'Miền Tây', latitude: 9.9347, longitude: 106.3453, highlight: 'Chùa Khmer'),
      Destination(id: 'dong_thap', name: 'Đồng Tháp', region: 'Miền Tây', latitude: 10.4938, longitude: 105.6882, highlight: 'Tràm Chim, Sa Đéc'),
      Destination(id: 'an_giang', name: 'An Giang', region: 'Miền Tây', latitude: 10.5216, longitude: 105.1259, highlight: 'Núi Cấm, rừng tràm Trà Sư'),
      Destination(id: 'kien_giang', name: 'Kiên Giang', region: 'Miền Tây', latitude: 10.0125, longitude: 105.0809, highlight: 'Hà Tiên, biển đảo'),
      Destination(id: 'phu_quoc', name: 'Phú Quốc', region: 'Miền Tây', latitude: 10.2899, longitude: 103.9840, highlight: 'Đảo ngọc'),
      Destination(id: 'can_tho', name: 'Cần Thơ', region: 'Miền Tây', latitude: 10.0452, longitude: 105.7469, highlight: 'Chợ nổi Cái Răng'),
      Destination(id: 'hau_giang', name: 'Hậu Giang', region: 'Miền Tây', latitude: 9.7579, longitude: 105.6413, highlight: 'Lung Ngọc Hoàng'),
      Destination(id: 'soc_trang', name: 'Sóc Trăng', region: 'Miền Tây', latitude: 9.6025, longitude: 105.9739, highlight: 'Chùa Dơi'),
      Destination(id: 'bac_lieu', name: 'Bạc Liêu', region: 'Miền Tây', latitude: 9.2940, longitude: 105.7216, highlight: 'Nhà công tử Bạc Liêu'),
      Destination(id: 'ca_mau', name: 'Cà Mau', region: 'Miền Tây', latitude: 9.1768, longitude: 105.1524, highlight: 'Mũi Cà Mau'),
    ],
    'Miền Nam': [
      Destination(id: 'tp_hcm', name: 'TP.HCM', region: 'Miền Nam', latitude: 10.7769, longitude: 106.7009, highlight: 'Landmark 81, phố đi bộ Nguyễn Huệ'),
      Destination(id: 'dong_nai', name: 'Đồng Nai', region: 'Miền Nam', latitude: 11.0686, longitude: 107.1676, highlight: 'Vườn quốc gia Cát Tiên'),
      Destination(id: 'binh_duong', name: 'Bình Dương', region: 'Miền Nam', latitude: 11.3254, longitude: 106.4770, highlight: 'Thủ Dầu Một'),
      Destination(id: 'vung_tau', name: 'Vũng Tàu', region: 'Miền Nam', latitude: 10.4114, longitude: 107.1362, highlight: 'Biển Bãi Sau'),
      Destination(id: 'tay_ninh', name: 'Tây Ninh', region: 'Miền Nam', latitude: 11.3351, longitude: 106.1099, highlight: 'Núi Bà Đen'),
      Destination(id: 'binh_phuoc', name: 'Bình Phước', region: 'Miền Nam', latitude: 11.7512, longitude: 106.7235, highlight: 'Bù Gia Mập'),
    ],
    'Miền Trung': [
      Destination(id: 'thanh_hoa', name: 'Thanh Hóa', region: 'Miền Trung', latitude: 19.8067, longitude: 105.7852, highlight: 'Sầm Sơn'),
      Destination(id: 'nghe_an', name: 'Nghệ An', region: 'Miền Trung', latitude: 18.6796, longitude: 105.6813, highlight: 'Cửa Lò'),
      Destination(id: 'ha_tinh', name: 'Hà Tĩnh', region: 'Miền Trung', latitude: 18.3559, longitude: 105.8877, highlight: 'Thiên Cầm'),
      Destination(id: 'quang_binh', name: 'Quảng Bình', region: 'Miền Trung', latitude: 17.4689, longitude: 106.6223, highlight: 'Phong Nha - Kẻ Bàng'),
      Destination(id: 'quang_tri', name: 'Quảng Trị', region: 'Miền Trung', latitude: 16.7500, longitude: 107.2000, highlight: 'Địa đạo Vịnh Mốc'),
      Destination(id: 'hue', name: 'Huế', region: 'Miền Trung', latitude: 16.4637, longitude: 107.5909, highlight: 'Đại Nội'),
      Destination(id: 'da_nang', name: 'Đà Nẵng', region: 'Miền Trung', latitude: 16.0544, longitude: 108.2022, highlight: 'Bà Nà Hills, Mỹ Khê'),
      Destination(id: 'quang_nam', name: 'Quảng Nam', region: 'Miền Trung', latitude: 15.5394, longitude: 108.0191, highlight: 'Hội An'),
      Destination(id: 'quang_ngai', name: 'Quảng Ngãi', region: 'Miền Trung', latitude: 15.1214, longitude: 108.8044, highlight: 'Lý Sơn'),
      Destination(id: 'binh_dinh', name: 'Bình Định', region: 'Miền Trung', latitude: 13.7820, longitude: 109.2197, highlight: 'Quy Nhơn'),
      Destination(id: 'phu_yen', name: 'Phú Yên', region: 'Miền Trung', latitude: 13.0882, longitude: 109.0929, highlight: 'Gành Đá Đĩa'),
      Destination(id: 'khanh_hoa', name: 'Khánh Hòa', region: 'Miền Trung', latitude: 12.2388, longitude: 109.1967, highlight: 'Nha Trang'),
      Destination(id: 'ninh_thuan', name: 'Ninh Thuận', region: 'Miền Trung', latitude: 11.6739, longitude: 108.8629, highlight: 'Vĩnh Hy'),
      Destination(id: 'binh_thuan', name: 'Bình Thuận', region: 'Miền Trung', latitude: 10.9804, longitude: 108.2615, highlight: 'Mũi Né'),
    ],
    'Miền Bắc': [
      Destination(id: 'ha_noi', name: 'Hà Nội', region: 'Miền Bắc', latitude: 21.0285, longitude: 105.8542, highlight: 'Phố cổ, Hồ Gươm'),
      Destination(id: 'quang_ninh', name: 'Quảng Ninh', region: 'Miền Bắc', latitude: 20.9712, longitude: 107.0448, highlight: 'Vịnh Hạ Long'),
      Destination(id: 'ninh_binh', name: 'Ninh Bình', region: 'Miền Bắc', latitude: 20.2506, longitude: 105.9745, highlight: 'Tràng An, Tam Cốc'),
      Destination(id: 'ha_giang', name: 'Hà Giang', region: 'Miền Bắc', latitude: 22.8233, longitude: 104.9836, highlight: 'Cao nguyên đá Đồng Văn'),
      Destination(id: 'lao_cai', name: 'Lào Cai', region: 'Miền Bắc', latitude: 22.4809, longitude: 103.9755, highlight: 'Sa Pa, Fansipan'),
      Destination(id: 'sa_pa', name: 'Sa Pa', region: 'Miền Bắc', latitude: 22.3364, longitude: 103.8438, highlight: 'Fansipan, bản Cát Cát'),
      Destination(id: 'son_la', name: 'Sơn La', region: 'Miền Bắc', latitude: 21.3270, longitude: 103.9141, highlight: 'Mộc Châu'),
    ],
  };

  static List<String> get regionOrder => byRegion.keys.toList();

  static List<Destination> get allDestinations =>
      byRegion.values.expand((items) => items).toList();
}
