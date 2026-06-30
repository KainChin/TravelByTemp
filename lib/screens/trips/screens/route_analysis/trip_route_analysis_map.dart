// ignore_for_file: use_string_in_part_of_directives

part of trip_route_analysis_screen;

class _RouteMapCard extends StatefulWidget {
  const _RouteMapCard({required this.analysis, this.fillHeight = false});

  final TripRouteAnalysis analysis;
  final bool fillHeight;

  @override
  State<_RouteMapCard> createState() => _RouteMapCardState();
}

class _RouteMapCardState extends State<_RouteMapCard> {
  List<DestinationPoint> get _points {
    final points = [
      DestinationPoint(
        id: 'departure',
        name: widget.analysis.departure.name,
        latitude: widget.analysis.departure.latitude,
        longitude: widget.analysis.departure.longitude,
      ),
    ];
    final seen = <String>{'departure'};
    for (final leg in widget.analysis.legs) {
      final point = leg.to;
      final key = point.id.isNotEmpty
          ? point.id
          : '${point.name}-${point.latitude}-${point.longitude}';
      if (seen.add(key)) {
        points.add(
          DestinationPoint(
            id: key,
            name: point.name,
            latitude: point.latitude,
            longitude: point.longitude,
          ),
        );
      }
    }
    return points;
  }

  List<LatLng> get _latLngs => _points.map((point) => point.latLng).toList();

  List<Marker> get _markers {
    return _points.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      return Marker(
        point: point.latLng,
        width: 96,
        height: 54,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: index == 0 ? const Color(0xFF0B7D4B) : const Color(0xFFEF4444),
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
                index == 0 ? 'S' : '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 6),
                ],
              ),
              child: Text(
                point.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  LatLng get _initialCenter {
    final points = _points;
    final avgLat =
        points.fold<double>(0, (sum, point) => sum + point.latitude) / points.length;
    final avgLng =
        points.fold<double>(0, (sum, point) => sum + point.longitude) / points.length;
    return LatLng(avgLat, avgLng);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: widget.fillHeight ? double.infinity : 430,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: 6,
            initialCameraFit: _latLngs.length > 1
                ? CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(_latLngs),
                    padding: const EdgeInsets.all(42),
                  )
                : null,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.vietai.travel',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _latLngs,
                  color: const Color(0xFF0B7D4B),
                  strokeWidth: 5,
                ),
              ],
            ),
            MarkerLayer(markers: _markers),
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
    );
  }
}

