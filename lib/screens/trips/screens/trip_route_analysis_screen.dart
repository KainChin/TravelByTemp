import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/budget_tier.dart';
import '../models/route_analysis.dart';
import '../services/trip_itinerary_service.dart';
import 'trip_itinerary_result_screen.dart';

class TripRouteAnalysisScreen extends StatefulWidget {
  const TripRouteAnalysisScreen({
    super.key,
    required this.analysis,
    required this.departureDate,
    required this.returnDate,
    required this.peopleCount,
    required this.budgetPerPerson,
  });

  final TripRouteAnalysis analysis;
  final DateTime departureDate;
  final DateTime returnDate;
  final int peopleCount;
  final double budgetPerPerson;

  @override
  State<TripRouteAnalysisScreen> createState() => _TripRouteAnalysisScreenState();
}

class _TripRouteAnalysisScreenState extends State<TripRouteAnalysisScreen> {
  bool _isGenerating = false;

  Future<void> _generateItinerary() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    final service = TripItineraryService();
    try {
      final result = await service.generate(
        destinations: widget.analysis.destinations,
        departureDate: widget.departureDate,
        returnDate: widget.returnDate,
        peopleCount: widget.peopleCount,
        budgetPerPerson: widget.budgetPerPerson,
        departurePoint: widget.analysis.departure.name,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripItineraryResultScreen(
            response: result.response,
            itinerary: result.itinerary,
            itineraryId: result.itineraryId,
          ),
        ),
      );
    } on TripItineraryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      service.dispose();
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = widget.analysis;
    final detailChildren = _detailChildren(analysis);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Khoảng cách & phương tiện'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            if (!wide) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _RouteTitle(analysis: analysis),
                  const SizedBox(height: 14),
                  _RouteMapCard(analysis: analysis),
                  const SizedBox(height: 14),
                  ...detailChildren,
                ],
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RouteTitle(analysis: analysis),
                        const SizedBox(height: 14),
                        Expanded(child: _RouteMapCard(analysis: analysis, fillHeight: true)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  SizedBox(
                    width: 460,
                    child: _DetailsRail(children: detailChildren),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _detailChildren(TripRouteAnalysis analysis) {
    return [
      _LegList(analysis: analysis),
      const SizedBox(height: 14),
      _SummaryCard(
        analysis: analysis,
        budgetPerPerson: widget.budgetPerPerson,
      ),
      const SizedBox(height: 12),
      ElevatedButton.icon(
        onPressed: _isGenerating ? null : _generateItinerary,
        icon: _isGenerating
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.auto_awesome, color: Colors.white),
        label: Text(
          _isGenerating ? 'ĐANG TẠO LỊCH TRÌNH...' : 'TẠO LỊCH TRÌNH',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0FA958),
          disabledBackgroundColor: Colors.grey.shade300,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ];
  }
}

class _RouteMapCard extends StatefulWidget {
  const _RouteMapCard({required this.analysis, this.fillHeight = false});

  final TripRouteAnalysis analysis;
  final bool fillHeight;

  @override
  State<_RouteMapCard> createState() => _RouteMapCardState();
}

class _RouteMapCardState extends State<_RouteMapCard> {
  List<DestinationPoint> get _points {
    return [
      DestinationPoint(
        id: 'departure',
        name: widget.analysis.departure.name,
        latitude: widget.analysis.departure.latitude,
        longitude: widget.analysis.departure.longitude,
      ),
      ...widget.analysis.destinations.map(
        (item) => DestinationPoint(
          id: item.destination.id,
          name: item.destination.name,
          latitude: item.destination.latitude,
          longitude: item.destination.longitude,
        ),
      ),
    ];
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

class _RouteTitle extends StatelessWidget {
  const _RouteTitle({required this.analysis});

  final TripRouteAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E4)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F4E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.route, color: Color(0xFF0B7D4B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tuyến hành trình',
                  style: TextStyle(
                    color: Color(0xFF647067),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  analysis.routeTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0B7D4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsRail extends StatelessWidget {
  const _DetailsRail({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120B7D4B),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text(
            'Chi tiết hành trình',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B1F1C),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Khoảng cách từng chặng, các mốc cần đi qua và tổng quan chuyến đi.',
            style: TextStyle(color: Color(0xFF647067), fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class DestinationPoint {
  const DestinationPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;

  LatLng get latLng => LatLng(latitude, longitude);
}

class _LegList extends StatelessWidget {
  const _LegList({required this.analysis});

  final TripRouteAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: analysis.legs.map((leg) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: const Color(0xFFE0F4E9),
                  child: Text('${leg.order}', style: const TextStyle(color: Color(0xFF0B7D4B), fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(leg.routeLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      _LegTransportChip(leg: leg),
                      const SizedBox(height: 4),
                      Text(leg.reason, style: const TextStyle(color: Color(0xFF647067), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LegTransportChip extends StatelessWidget {
  const _LegTransportChip({required this.leg});

  final RouteLeg leg;

  TransportMode get mode => leg.recommendedMode;

  IconData get _icon {
    switch (mode) {
      case TransportMode.motorbike:
        return Icons.two_wheeler;
      case TransportMode.car:
        return Icons.directions_car_filled_outlined;
      case TransportMode.train:
        return Icons.train_outlined;
      case TransportMode.flight:
        return Icons.flight_takeoff;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: const Color(0xFF0B7D4B)),
          const SizedBox(width: 5),
          Text(
            '${transportLabel(mode)} • ${leg.distanceKm.toStringAsFixed(0)} km • ${formatHours(leg.recommendedHours)}',
            style: const TextStyle(
              color: Color(0xFF0B7D4B),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.analysis,
    required this.budgetPerPerson,
  });

  final TripRouteAnalysis analysis;
  final double budgetPerPerson;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng quan hành trình', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _InfoRow(label: 'Tổng khoảng cách', value: '${analysis.totalDistanceKm.toStringAsFixed(0)} km'),
          _InfoRow(label: 'Số chặng di chuyển', value: '${analysis.legs.length} chặng'),
          _InfoRow(label: 'Thời gian ước tính', value: formatHours(analysis.optimizedHours)),
          _InfoRow(label: 'Ngân sách mỗi người', value: BudgetTier.formatCurrency(budgetPerPerson)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF647067)))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E4)),
      ),
      child: child,
    );
  }
}
