// ignore_for_file: use_string_in_part_of_directives
part of destination_detail_screen;

class _Hero extends StatelessWidget {
  const _Hero({required this.destination, required this.loading});

  final Destination destination;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetworkImageCard(
            imageUrl: destination.imageUrl,
            height: 300,
            borderRadius: BorderRadius.zero,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.32),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.46),
                ],
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: _RoundIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.maybePop(context),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loading) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Icon(Icons.thermostat, size: 17, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('${destination.avgTempC.toStringAsFixed(0)}C'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(icon: Icons.star, label: 'Rating', value: destination.ratingLabel),
        const SizedBox(width: 10),
        _StatCard(icon: Icons.near_me, label: 'Distance', value: destination.distanceLabel),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.payments_outlined,
          label: 'Budget',
          value: destination.price ?? 'Flexible',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 86,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const Spacer(),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.category_outlined, 'Type', destination.category),
      (Icons.place_outlined, 'Province', destination.location ?? 'Vietnam'),
      (Icons.cloud_outlined, 'Weather fit', _climateLabel(destination.climate)),
      (Icons.pin_drop_outlined, 'Coordinates', _coords(destination)),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.85,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(item.$1, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          item.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  String _coords(Destination destination) {
    final lat = destination.latitude;
    final lon = destination.longitude;
    if (lat == null || lon == null) return 'Unknown';
    return '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';
  }

  String _climateLabel(DestinationClimate climate) {
    return switch (climate) {
      DestinationClimate.hot => 'Hot',
      DestinationClimate.warm => 'Warm',
      DestinationClimate.cool => 'Cool',
      DestinationClimate.cold => 'Cold',
    };
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(width: 48, height: 48, child: Icon(icon)),
      ),
    );
  }
}
