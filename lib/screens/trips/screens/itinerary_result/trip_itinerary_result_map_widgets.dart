// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

class _RatedPlacesHint extends StatelessWidget {
  const _RatedPlacesHint({required this.day, required this.count});

  final Object? day;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(999),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _showRatedPlacesSheet(context, day),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rate_rounded, size: 17, color: Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              Text(
                '$count địa điểm 4.0+',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatedPlaceTile extends StatelessWidget {
  const _RatedPlaceTile({required this.place});

  final _RatedPlace place;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7FAF8),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openMaps(place.activity),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _TripItineraryResultScreenState._primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.place_outlined,
                  color: _TripItineraryResultScreenState._primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _TripItineraryResultScreenState._muted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      children: [
                        _MapSmallChip(
                          icon: Icons.star_rate_rounded,
                          label: '${place.rating.toStringAsFixed(1)}/5',
                        ),
                        _MapSmallChip(
                          icon: Icons.category_outlined,
                          label: place.category,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.map_outlined, color: _TripItineraryResultScreenState._primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapSmallChip extends StatelessWidget {
  const _MapSmallChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _TripItineraryResultScreenState._primary),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.stopsCount});

  final int stopsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 12)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.route_outlined, size: 17, color: _TripItineraryResultScreenState._primary),
          const SizedBox(width: 6),
          Text(
            '$stopsCount mốc cần đi',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _MapControlButton(icon: Icons.my_location_outlined, tooltip: 'Định vị'),
        SizedBox(height: 8),
        _MapControlButton(icon: Icons.add, tooltip: 'Phóng to'),
        SizedBox(height: 8),
        _MapControlButton(icon: Icons.remove, tooltip: 'Thu nhỏ'),
        SizedBox(height: 8),
        _MapControlButton(icon: Icons.layers_outlined, tooltip: 'Lớp bản đồ'),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {},
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 19, color: _TripItineraryResultScreenState._ink),
          ),
        ),
      ),
    );
  }
}

