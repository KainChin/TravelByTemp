// ignore_for_file: use_string_in_part_of_directives

part of trip_route_analysis_screen;

class _LegList extends StatelessWidget {
  const _LegList({
    required this.analysis,
    required this.onChangeMode,
  });

  final TripRouteAnalysis analysis;
  final void Function(RouteLeg leg, TransportOption option) onChangeMode;

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
            onChangeMode(leg, option);
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
                      if (leg.recommendedMode == TransportMode.flight ||
                          leg.recommendedMode == TransportMode.ferry) ...[
                        const SizedBox(height: 8),
                        _LegMultiLegBreakdown(leg: leg),
                      ],
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

/// Hiển thị breakdown sub-leg trong _LegList. Dùng `effectiveJourneyForLeg`
/// để đảm bảo cùng nguồn dữ liệu với popup chọn phương tiện + _SummaryCard.
class _LegMultiLegBreakdown extends StatelessWidget {
  const _LegMultiLegBreakdown({required this.leg});

  final RouteLeg leg;

  @override
  Widget build(BuildContext context) {
    final journey = effectiveJourneyForLeg(leg);
    if (journey == null || !journey.isMultiLeg) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCEEE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.alt_route, size: 12, color: Color(0xFF0B7D4B)),
            SizedBox(width: 4),
            Text(
              'Chi tiết từng chặng',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0B7D4B),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          ...journey.legs.asMap().entries.map((entry) {
            final i = entry.key;
            final legItem = entry.value;
            final subLabel = legItem.subMode == TransitSubMode.na
                ? ''
                : ' (${legItem.subMode.label})';
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F4E9),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0B7D4B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${legItem.note ?? '${legItem.fromLabel} → ${legItem.toLabel}'}$subLabel',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B1F1C),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          [
                            if (legItem.distanceKm > 0)
                              '${legItem.distanceKm.toStringAsFixed(0)} km',
                            legItem.durationLabel,
                            if (legItem.costVnd > 0) legItem.costLabel,
                          ].where((s) => s.isNotEmpty).join(' • '),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF647067),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}


