// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

class TripMapSection extends StatelessWidget {
  const TripMapSection({
    super.key,
    required this.day,
    required this.height,
  });

  final Object? day;
  final double height;

  @override
  Widget build(BuildContext context) {
    final stops = _stopsFor(day);
    final points = stops.map((s) => s.point).toList();
    final center = points.isEmpty ? const LatLng(16.0544, 108.2022) : points.first;
    final scheme = Theme.of(context).colorScheme;
    final mapKey = ValueKey<String>(
      'trip-map-${_dayFingerprint(day)}',
    );

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _TripItineraryResultScreenState._line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              key: mapKey,
              options: MapOptions(
                initialCenter: center,
                initialZoom: points.length <= 1 ? 12 : 11,
                onTap: (tapPosition, point) => _showRatedPlacesSheet(context, day),
                initialCameraFit: points.length > 1
                    ? CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(points),
                        padding: const EdgeInsets.all(42),
                      )
                    : null,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.vietai.travel',
                ),
                if (points.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(points: points, color: scheme.primary, strokeWidth: 5),
                    ],
                  ),
                MarkerLayer(
                  markers: stops.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final stop = entry.value;
                    return Marker(
                      point: stop.point,
                      width: 104,
                      height: 62,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: index == 1
                                  ? const Color(0xFF0B7D4B)
                                  : _TripItineraryResultScreenState._accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              '$index',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: const [
                                BoxShadow(color: Color(0x1A000000), blurRadius: 6),
                              ],
                            ),
                            child: Text(
                              stop.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap',
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: _MapBadge(stopsCount: stops.length),
          ),
          Positioned(
            left: 14,
            bottom: 14,
            child: _RatedPlacesHint(day: day, count: _ratedPlacesFor(day).length),
          ),
          const Positioned(
            right: 14,
            top: 14,
            child: _MapControls(),
          ),
        ],
      ),
    );
  }
}

String _dayFingerprint(Object? day) {
  if (day is! Map) return 'empty';
  final activities = day['activities'];
  if (activities is List) {
    return activities.length.toString();
  }
  return '${day['day'] ?? 'day'}';
}


