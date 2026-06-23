/// Đại diện cho một điểm đến du lịch (vd: Vũng Tàu, Sa Pa...).
class Destination {
  final String id;
  final String name;
  final String region;
  final double distanceFromPreviousKm;

  const Destination({
    required this.id,
    required this.name,
    required this.region,
    this.distanceFromPreviousKm = 0,
  });
}

/// Một điểm đến đã được người dùng chọn vào hành trình,
/// kèm khoảng cách tính từ điểm trước đó (hiển thị dạng "xxx km từ ...").
class SelectedDestination {
  final Destination destination;
  final String fromLabel;
  final double distanceKm;

  const SelectedDestination({
    required this.destination,
    required this.fromLabel,
    required this.distanceKm,
  });

  String get subtitleLabel =>
      '${distanceKm.toStringAsFixed(0)} km từ $fromLabel';
}

/// Danh sách điểm đến mẫu, gom theo miền — dùng cho bottom sheet chọn điểm đến.
class DestinationCatalog {
  static const Map<String, List<Destination>> byRegion = {
    'Miền Bắc': [
      Destination(id: 'ha_noi', name: 'Hà Nội', region: 'Miền Bắc'),
      Destination(id: 'sa_pa', name: 'Sa Pa', region: 'Miền Bắc'),
    ],
    'Miền Trung': [
      Destination(id: 'da_nang', name: 'Đà Nẵng', region: 'Miền Trung'),
      Destination(id: 'hue', name: 'Huế', region: 'Miền Trung'),
    ],
    'Miền Nam': [
      Destination(id: 'vung_tau', name: 'Vũng Tàu', region: 'Miền Nam'),
      Destination(id: 'mui_ne', name: 'Mũi Né', region: 'Miền Nam'),
    ],
    'Miền Tây': [
      Destination(id: 'can_tho', name: 'Cần Thơ', region: 'Miền Tây'),
      Destination(id: 'phu_quoc', name: 'Phú Quốc', region: 'Miền Tây'),
    ],
  };

  static List<String> get regionOrder => byRegion.keys.toList();
}