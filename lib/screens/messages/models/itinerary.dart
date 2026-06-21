/// A single destination/stop inside an itinerary plan
/// (e.g. "Đà Lạt", "2 Ngày • 1 Đêm", "Ngày 1 - 2").
class ItineraryDestination {
  final String name;
  final String emoji;
  final String duration;
  final String dayLabel;
  final String thumbnailAsset;

  const ItineraryDestination({
    required this.name,
    required this.emoji,
    required this.duration,
    required this.dayLabel,
    required this.thumbnailAsset,
  });
}

/// A full itinerary plan rendered inside an [ItineraryCard], e.g.
/// "Đà Lạt 2N1Đ + Nha Trang 1N".
class ItineraryPlan {
  final String title;
  final String subtitle;
  final List<ItineraryDestination> destinations;

  const ItineraryPlan({
    required this.title,
    required this.subtitle,
    required this.destinations,
  });
}
