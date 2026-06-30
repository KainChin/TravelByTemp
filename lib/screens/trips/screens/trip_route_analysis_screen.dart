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
  late TripRouteAnalysis _analysis;

  @override
  void initState() {
    super.initState();
    _analysis = widget.analysis;
  }

  @override
  void didUpdateWidget(covariant TripRouteAnalysisScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.analysis != widget.analysis) {
      _analysis = widget.analysis;
    }
  }

  Future<void> _generateItinerary() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    final service = TripItineraryService();
    try {
      final result = await service.generate(
        destinations: _analysis.destinations,
        departureDate: widget.departureDate,
        returnDate: widget.returnDate,
        peopleCount: widget.peopleCount,
        budgetPerPerson: widget.budgetPerPerson,
        departurePoint: _analysis.departure.name,
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
    final analysis = _analysis;
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
      _LegList(
        analysis: analysis,
        onChangeMode: _changeLegMode,
      ),
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

  void _changeLegMode(RouteLeg leg, TransportMode mode, String reason) {
    final updated = _analysis.legs.map((item) {
      if (item.order != leg.order) return item;
      return item.copyWith(recommendedMode: mode, reason: reason);
    }).toList();
    setState(() => _analysis = _analysis.copyWith(legs: updated));
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
  const _LegList({
    required this.analysis,
    required this.onChangeMode,
  });

  final TripRouteAnalysis analysis;
  final void Function(RouteLeg leg, TransportMode mode, String reason) onChangeMode;

  Future<void> _showTransportPicker(BuildContext context, RouteLeg leg) async {
    final options = transportOptionsForLeg(leg);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _TransportPickerSheet(
          leg: leg,
          options: options,
          onSelected: (option) {
            Navigator.pop(context);
            onChangeMode(leg, option.mode, option.reason);
          },
        );
      },
    );
  }

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
                      if (leg.recommendedMode == TransportMode.flight) ...[
                        const SizedBox(height: 10),
                        const _FlightBookingLinks(),
                      ],
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showTransportPicker(context, leg),
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        label: const Text('Đổi phương tiện'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0B7D4B),
                          side: const BorderSide(color: Color(0xFFDCEEE5)),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
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

class _FlightBookingLinks extends StatelessWidget {
  const _FlightBookingLinks();

  static const _links = [
    _BookingLink(
      label: 'Đặt vé Vietnam Airlines',
      url: 'https://www.vietnamairlines.com/vn/vi/',
    ),
    _BookingLink(
      label: 'Đặt vé Vietjet Air',
      url: 'https://www.vietjetair.com/vi/',
    ),
    _BookingLink(
      label: 'Tìm vé trên Traveloka',
      url: 'https://www.traveloka.com/vi-vn/flight/airline/bamboo-airways.qh',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCEEE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flight_takeoff, size: 16, color: Color(0xFF0B7D4B)),
              SizedBox(width: 6),
              Text(
                'Đặt vé máy bay',
                style: TextStyle(
                  color: Color(0xFF1B1F1C),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _links.map((link) => _BookingLinkButton(link: link)).toList(),
          ),
        ],
      ),
    );
  }
}

class _BookingLinkButton extends StatelessWidget {
  const _BookingLinkButton({required this.link});

  final _BookingLink link;

  Future<void> _open() async {
    await launchUrl(
      Uri.parse(link.url),
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _open,
      icon: const Icon(Icons.open_in_new, size: 14),
      label: Text(link.label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0B7D4B),
        side: const BorderSide(color: Color(0xFFDCEEE5)),
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class _BookingLink {
  const _BookingLink({
    required this.label,
    required this.url,
  });

  final String label;
  final String url;
}

class _LegTransportChip extends StatelessWidget {
  const _LegTransportChip({required this.leg});

  final RouteLeg leg;

  TransportMode get mode => leg.recommendedMode;

  IconData get _icon => _transportIcon(mode);

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

IconData _transportIcon(TransportMode mode) {
  switch (mode) {
    case TransportMode.motorbike:
      return Icons.two_wheeler;
    case TransportMode.car:
      return Icons.directions_car_filled_outlined;
    case TransportMode.coach:
      return Icons.directions_bus_outlined;
    case TransportMode.train:
      return Icons.train_outlined;
    case TransportMode.ferry:
      return Icons.directions_boat_filled_outlined;
    case TransportMode.flight:
      return Icons.flight_takeoff;
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
    final budgetUsage = analysis.budgetUsagePercent(budgetPerPerson);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng quan hành trình', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _InfoRow(label: 'Tổng khoảng cách', value: '${analysis.totalDistanceKm.toStringAsFixed(0)} km'),
          _InfoRow(label: 'Tổng thời gian di chuyển', value: formatHours(analysis.optimizedHours)),
          _InfoRow(label: 'Tổng số chặng', value: '${analysis.legs.length} chặng'),
          _InfoRow(label: 'Số lần chuyển phương tiện', value: '${analysis.transferCount} lần'),
          _InfoRow(
            label: 'Chi phí di chuyển dự kiến',
            value: BudgetTier.formatCurrency(analysis.estimatedRouteCostVnd),
          ),
          _InfoRow(label: 'Ngân sách người dùng', value: BudgetTier.formatCurrency(budgetPerPerson)),
          _BudgetUsageRow(percent: budgetUsage),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: analysis.aiBadges.map((badge) => _SummaryPill(text: badge)).toList(),
          ),
          if (analysis.importantNotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...analysis.importantNotes.map((note) => _SummaryNote(text: note)),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FBF8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCEEE5)),
            ),
            child: Text(
              analysis.aiRecommendation,
              style: const TextStyle(
                color: Color(0xFF38443C),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _TransportPickerSheet extends StatelessWidget {
  const _TransportPickerSheet({
    required this.leg,
    required this.options,
    required this.onSelected,
  });

  final RouteLeg leg;
  final List<TransportOption> options;
  final ValueChanged<TransportOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              leg.routeLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B1F1C),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Chỉ các phương tiện khả thi mới có thể chọn.',
              style: TextStyle(color: Color(0xFF647067), fontSize: 12),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final selected = option.mode == leg.recommendedMode;
                  return _TransportOptionTile(
                    option: option,
                    selected: selected,
                    onTap: option.isAvailable ? () => onSelected(option) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransportOptionTile extends StatelessWidget {
  const _TransportOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final TransportOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = option.isAvailable;
    final foreground = enabled ? const Color(0xFF1B1F1C) : const Color(0xFF8A948D);
    final border = selected ? const Color(0xFF0B7D4B) : const Color(0xFFE2E8E4);
    final background = selected ? const Color(0xFFEAF5F0) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: enabled ? background : const Color(0xFFF6F8F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: enabled ? const Color(0xFFE0F4E9) : const Color(0xFFE9EEE9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _transportIcon(option.mode),
                color: enabled ? const Color(0xFF0B7D4B) : const Color(0xFF8A948D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transportLabel(option.mode),
                          style: TextStyle(
                            color: foreground,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle, color: Color(0xFF0B7D4B), size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatHours(option.durationHours)} • ${BudgetTier.formatCurrency(option.estimatedCostVnd)}',
                    style: TextStyle(
                      color: enabled ? const Color(0xFF0B7D4B) : const Color(0xFF8A948D),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.reason,
                    style: TextStyle(
                      color: enabled ? const Color(0xFF647067) : const Color(0xFF9AA39D),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tone = _BadgeTone.fromText(text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tone.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BadgeTone {
  const _BadgeTone(this.background, this.foreground);

  final Color background;
  final Color foreground;

  static _BadgeTone fromText(String value) {
    if (value.contains('Phức tạp')) {
      return const _BadgeTone(Color(0xFFFFE4E6), Color(0xFFBE123C));
    }
    if (value.contains('Trung bình') || value.contains('Cân bằng')) {
      return const _BadgeTone(Color(0xFFFFF7CC), Color(0xFF9A6B00));
    }
    if (value.contains('Nhanh nhất')) {
      return const _BadgeTone(Color(0xFFE0F2FE), Color(0xFF0369A1));
    }
    if (value.contains('Tiết kiệm nhất')) {
      return const _BadgeTone(Color(0xFFEAF5F0), Color(0xFF0B7D4B));
    }
    return const _BadgeTone(Color(0xFFEAF5F0), Color(0xFF0B7D4B));
  }
}

class _SummaryNote extends StatelessWidget {
  const _SummaryNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 15, color: Color(0xFF647067)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF647067),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetUsageRow extends StatelessWidget {
  const _BudgetUsageRow({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final rounded = percent.round();
    final remaining = (100 - percent).clamp(0, 100).round();
    final tone = _toneForPercent(percent);
    final status = percent > 100
        ? 'Vượt ngân sách'
        : percent >= 80
            ? 'Gần chạm ngân sách'
            : 'Trong ngân sách';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Đã sử dụng',
                  style: TextStyle(color: Color(0xFF647067)),
                ),
              ),
              _BudgetPill(text: '$rounded% ngân sách', tone: tone),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ngân sách còn lại',
                  style: TextStyle(color: Color(0xFF647067)),
                ),
              ),
              _BudgetPill(
                text: percent > 100 ? '0% • $status' : '$remaining% • $status',
                tone: tone,
              ),
            ],
          ),
        ],
      ),
    );
  }

  _BadgeTone _toneForPercent(double value) {
    if (value > 100) {
      return const _BadgeTone(Color(0xFFFFE4E6), Color(0xFFBE123C));
    }
    if (value >= 80) {
      return const _BadgeTone(Color(0xFFFFF7CC), Color(0xFF9A6B00));
    }
    return const _BadgeTone(Color(0xFFEAF5F0), Color(0xFF0B7D4B));
  }
}

class _BudgetPill extends StatelessWidget {
  const _BudgetPill({required this.text, required this.tone});

  final String text;
  final _BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tone.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
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
