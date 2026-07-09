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
