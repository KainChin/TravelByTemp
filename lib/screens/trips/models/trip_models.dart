class TripDestination {
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String? distanceText;
  final String? durationText;
  final String? bestRoute;

  const TripDestination({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.distanceText,
    this.durationText,
    this.bestRoute,
  });

  TripDestination copyWith({
    String? distanceText,
    String? durationText,
    String? bestRoute,
  }) {
    return TripDestination(
      name: name,
      address: address,
      lat: lat,
      lng: lng,
      distanceText: distanceText ?? this.distanceText,
      durationText: durationText ?? this.durationText,
      bestRoute: bestRoute ?? this.bestRoute,
    );
  }
}
