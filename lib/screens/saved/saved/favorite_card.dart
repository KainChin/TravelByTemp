// ignore_for_file: use_string_in_part_of_directives
part of saved_screen;

class _FavoriteCard extends StatefulWidget {
  const _FavoriteCard({
    required this.favorite,
    required this.onOpen,
    required this.onRemove,
  });

  final FavoriteDestination favorite;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  State<_FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends State<_FavoriteCard> {
  var _scale = 1.0;
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final destination = widget.favorite.destination;
    // Default avgTempC comes from region in Destination.fromApi; only label as
    // Sunny / Cool based on that real value.
    final avg = destination.avgTempC;
    final weather = avg <= 0
        ? 'Đang cập nhật'
        : avg >= 28
            ? 'Nắng ấm'
            : avg >= 22
                ? 'Dễ chịu'
                : 'Mát mẻ';
    final bestSeason = avg <= 0
        ? 'Đang cập nhật'
        : avg >= 26
            ? 'Mùa khô'
            : avg >= 20
                ? 'Mùa mát'
                : 'Mùa đông';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _scale = 0.985),
          onTapUp: (_) {
            setState(() => _scale = 1.0);
            widget.onOpen();
          },
          onTapCancel: () => setState(() => _scale = 1.0),
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _hovered ? const Color(0xFFA7F3D0) : const Color(0xFFECFDF5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: _hovered ? 0.08 : 0.03),
                    blurRadius: _hovered ? 22 : 16,
                    offset: Offset(0, _hovered ? 10 : 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 112,
                      height: 112,
                      child: NetworkImageCard(
                        imageUrl: destination.imageUrl,
                        height: 112,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            destination.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            destination.location ?? destination.tagline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 7,
                            children: [
                              _InlineMeta(icon: Icons.star_rounded, label: destination.ratingLabel, color: const Color(0xFFF59E0B)),
                              _InlineMeta(icon: Icons.navigation_rounded, label: destination.distanceLabel, color: const Color(0xFF10B981)),
                              _InlineMeta(icon: Icons.wb_sunny_rounded, label: weather, color: const Color(0xFFF97316)),
                              _InlineMeta(icon: Icons.event_available_rounded, label: bestSeason, color: const Color(0xFF0D9488)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        tooltip: 'Bỏ lưu địa điểm',
                        onPressed: widget.onRemove,
                        icon: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}
