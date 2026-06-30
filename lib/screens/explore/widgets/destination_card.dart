import 'package:flutter/material.dart';
import 'package:assignment/core/widgets/safe_network_image.dart';
import '../models/destination_model.dart';

class DestinationCard extends StatelessWidget {
  final DestinationModel destination;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onTap;

  const DestinationCard({
    super.key,
    required this.destination,
    this.onFavoriteTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardImage(
              imageUrl: destination.imageUrl,
              isFavorite: destination.isFavorite,
              onFavoriteTap: onFavoriteTap,
            ),
            const SizedBox(height: 8),
            Text(
              destination.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              destination.province,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            _RatingRow(rating: destination.rating),
          ],
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final String imageUrl;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const _CardImage({
    required this.imageUrl,
    required this.isFavorite,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 140,
        width: 150,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeNetworkImage(
              url: imageUrl,
              fit: BoxFit.cover,
              source: 'destination card image',
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onFavoriteTap,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 17,
                    color: isFavorite ? Colors.red : const Color(0xFF374151),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  const _RatingRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}
