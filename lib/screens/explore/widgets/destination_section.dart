import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../models/region_model.dart';
import 'destination_card.dart';

class DestinationSection extends StatelessWidget {
  final RegionModel region;
  final List<DestinationModel> destinations;
  final void Function(String destinationId)? onFavoriteTap;
  final VoidCallback? onViewAll;

  const DestinationSection({
    super.key,
    required this.region,
    required this.destinations,
    this.onFavoriteTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          prefix: 'Điểm đến nổi bật tại ',
          highlight: region.name,
          onViewAll: onViewAll,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: destinations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => DestinationCard(
              destination: destinations[i],
              onFavoriteTap: () => onFavoriteTap?.call(destinations[i].id),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String prefix;
  final String highlight;
  final VoidCallback? onViewAll;

  const _SectionHeader({
    required this.prefix,
    required this.highlight,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: prefix,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                TextSpan(
                  text: highlight,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: const Row(
            children: [
              Text(
                'Xem tất cả',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16A34A),
                ),
              ),
              SizedBox(width: 2),
              Icon(Icons.arrow_forward_ios, size: 11, color: Color(0xFF16A34A)),
            ],
          ),
        ),
      ],
    );
  }
}
