// ignore_for_file: use_string_in_part_of_directives

part of trip_route_analysis_screen;

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


