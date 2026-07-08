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

  /// Tính danh sách polyline theo mode của từng leg.
  ///
  /// Với road-based mode (car/motorbike/coach/train) → vẽ 1 line thẳng nối
  /// origin → destination (gần đúng, sẽ được làm cong bởi tile layer).
  ///
  /// Với flight/ferry → vẽ multi-leg: origin → hub (sân bay/cảng) → hub →
  /// destination. KHÔNG vẽ line thẳng xuyên biển.
  List<List<LatLng>> get _polylineSegments {
    final segments = <List<LatLng>>[];
    Destination? prev = widget.analysis.departure;
    if (prev.latitude == 0 && prev.longitude == 0) prev = null;
    for (final leg in widget.analysis.legs) {
      final origin = leg.from ?? prev;
      if (origin == null) {
        segments.add([LatLng(leg.to.latitude, leg.to.longitude)]);
        prev = leg.to;
        continue;
      }
      final mode = leg.recommendedMode;
      switch (mode) {
        case TransportMode.flight:
          final journey = buildMultiLegJourney(
            mode: TransportMode.flight, origin: origin, destination: leg.to,
          );
          if (journey != null && journey.legs.isNotEmpty) {
            final waypoints = <LatLng>[LatLng(origin.latitude, origin.longitude)];
            for (final jl in journey.legs) {
              if (jl.fromLabel.startsWith('Sân bay ')) {
                final hubName = jl.fromLabel.substring('Sân bay '.length);
                final hub = _findAirportByName(hubName);
                if (hub != null) {
                  waypoints.add(LatLng(hub.latitude, hub.longitude));
                }
              }
              if (jl.toLabel.startsWith('Sân bay ')) {
                final hubName = jl.toLabel.substring('Sân bay '.length);
                final hub = _findAirportByName(hubName);
                if (hub != null) {
                  waypoints.add(LatLng(hub.latitude, hub.longitude));
                }
              }
            }
            waypoints.add(LatLng(leg.to.latitude, leg.to.longitude));
            segments.add(_dedupLatLng(waypoints));
          } else {
            segments.add([
              LatLng(origin.latitude, origin.longitude),
              LatLng(leg.to.latitude, leg.to.longitude),
            ]);
          }
          break;
        case TransportMode.ferry:
          final journey = buildMultiLegJourney(
            mode: TransportMode.ferry, origin: origin, destination: leg.to,
          );
          if (journey != null && journey.legs.isNotEmpty) {
            final waypoints = <LatLng>[LatLng(origin.latitude, origin.longitude)];
            for (final jl in journey.legs) {
              if (jl.fromLabel.startsWith('Cảng ')) {
                final hubName = jl.fromLabel.substring('Cảng '.length);
                final hub = _findPortByName(hubName);
                if (hub != null) {
                  waypoints.add(LatLng(hub.latitude, hub.longitude));
                }
              }
              if (jl.toLabel.startsWith('Cảng ')) {
                final hubName = jl.toLabel.substring('Cảng '.length);
                final hub = _findPortByName(hubName);
                if (hub != null) {
                  waypoints.add(LatLng(hub.latitude, hub.longitude));
                }
              }
            }
            waypoints.add(LatLng(leg.to.latitude, leg.to.longitude));
            segments.add(_dedupLatLng(waypoints));
          } else {
            segments.add([
              LatLng(origin.latitude, origin.longitude),
              LatLng(leg.to.latitude, leg.to.longitude),
            ]);
          }
          break;
        case TransportMode.motorbike:
        case TransportMode.car:
        case TransportMode.coach:
        case TransportMode.train:
          segments.add([
            LatLng(origin.latitude, origin.longitude),
            LatLng(leg.to.latitude, leg.to.longitude),
          ]);
          break;
      }
      prev = leg.to;
    }
    return segments;
  }

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
              polylines: _polylineSegments.map((pts) {
                // Phân biệt line liền (đường bộ) và line đứt (bay/phà).
                final isWater = pts.length > 2;
                return Polyline(
                  points: pts,
                  color: const Color(0xFF0B7D4B),
                  strokeWidth: isWater ? 4 : 5,
                  pattern: isWater
                      ? StrokePattern.dashed(segments: const [10, 6])
                      : const StrokePattern.solid(),
                );
              }).toList(),
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

/// Heuristic: nếu polyline có > 2 điểm → có khả năng là multi-leg qua hub
/// (bay/phà). Đơn giản và đủ cho UI hint.
bool _isWaterMode(List<LatLng> pts) => pts.length > 2;

/// Loại bỏ LatLng trùng lặp liên tiếp.
List<LatLng> _dedupLatLng(List<LatLng> pts) {
  final out = <LatLng>[];
  for (final p in pts) {
    if (out.isEmpty || out.last.latitude != p.latitude ||
        out.last.longitude != p.longitude) {
      out.add(p);
    }
  }
  return out;
}

/// Lookup hub theo tên (chỉ dùng trong map để vẽ waypoint).
TransportHub? _findAirportByName(String name) {
  for (final h in _airportsForMap) {
    if (h.name == name) return h;
  }
  return null;
}

TransportHub? _findPortByName(String name) {
  for (final h in _portsForMap) {
    if (h.name == name) return h;
  }
  return null;
}

/// Mirror const list của file infrastructure. Không dùng part để tránh
/// forward-reference; copy lại tối thiểu các hub cần thiết cho map.
final List<TransportHub> _airportsForMap = const [
  TransportHub(id: 'HAN', name: 'Nội Bài (Hà Nội)',
      latitude: 21.2187, longitude: 105.8072, landmass: LandmassId.mainland),
  TransportHub(id: 'HPH', name: 'Cát Bi (Hải Phòng)',
      latitude: 20.8194, longitude: 106.7249, landmass: LandmassId.mainland),
  TransportHub(id: 'DAD', name: 'Đà Nẵng',
      latitude: 16.0439, longitude: 108.1994, landmass: LandmassId.mainland),
  TransportHub(id: 'CXR', name: 'Cam Ranh (Khánh Hòa)',
      latitude: 11.9981, longitude: 109.2192, landmass: LandmassId.mainland),
  TransportHub(id: 'SGN', name: 'Tân Sơn Nhất (TP.HCM)',
      latitude: 10.8188, longitude: 106.6519, landmass: LandmassId.mainland),
  TransportHub(id: 'VCS', name: 'Côn Đảo',
      latitude: 8.7317, longitude: 106.6328, landmass: LandmassId.conDao),
  TransportHub(id: 'PQC', name: 'Phú Quốc',
      latitude: 10.1700, longitude: 103.9931, landmass: LandmassId.phuQuoc),
];

final List<TransportHub> _portsForMap = const [
  TransportHub(id: 'PORT_RG', name: 'Rạch Giá',
      latitude: 9.9937, longitude: 105.0839, landmass: LandmassId.mainland,
      kind: TransportHubKind.ferryPort),
  TransportHub(id: 'PORT_VT', name: 'Vũng Tàu (Cầu Đá)',
      latitude: 10.3624, longitude: 107.0803, landmass: LandmassId.mainland,
      kind: TransportHubKind.ferryPort),
  TransportHub(id: 'PORT_PQ', name: 'Bãi Vòng (Phú Quốc)',
      latitude: 10.0803, longitude: 104.3603, landmass: LandmassId.phuQuoc,
      kind: TransportHubKind.ferryPort),
  TransportHub(id: 'PORT_CD', name: 'Bến Đầm (Côn Đảo)',
      latitude: 8.6831, longitude: 106.6133, landmass: LandmassId.conDao,
      kind: TransportHubKind.ferryPort),
];

