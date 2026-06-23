import 'package:flutter/material.dart';

import '../messages_styles.dart';
import '../models/itinerary.dart';

/// Card rendered after an AI message that proposes a trip plan, e.g.
/// "Đà Lạt 2N1Đ + Nha Trang 1N" with a row per destination and a
/// "Xem chi tiết lịch trình" footer link.
class ItineraryCard extends StatelessWidget {
  final ItineraryPlan plan;
  final VoidCallback? onViewDetails;
  final ValueChanged<ItineraryDestination>? onDestinationTap;

  const ItineraryCard({
    super.key,
    required this.plan,
    this.onViewDetails,
    this.onDestinationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MessageSpacing.lg),
      decoration: BoxDecoration(
        color: MessageColors.cardWhite,
        borderRadius: BorderRadius.circular(MessageRadius.card),
        boxShadow: MessageShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(plan.title, style: MessageTextStyles.itineraryTitle),
          const SizedBox(height: 2),
          Text(plan.subtitle, style: MessageTextStyles.itinerarySubtitle),
          const SizedBox(height: MessageSpacing.lg),
          ...plan.destinations.map(
            (destination) => Padding(
              padding: const EdgeInsets.only(bottom: MessageSpacing.md),
              child: _DestinationRow(
                destination: destination,
                onTap: onDestinationTap == null
                    ? null
                    : () => onDestinationTap!(destination),
              ),
            ),
          ),
          const SizedBox(height: MessageSpacing.xs),
          const Divider(color: MessageColors.divider, height: 1),
          const SizedBox(height: MessageSpacing.md),
          InkWell(
            onTap: onViewDetails,
            child: Row(
              children: const [
                Text('Xem chi tiết lịch trình', style: MessageTextStyles.footerLink),
                Spacer(),
                Icon(Icons.chevron_right, size: 18, color: MessageColors.primaryGreen),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationRow extends StatelessWidget {
  final ItineraryDestination destination;
  final VoidCallback? onTap;

  const _DestinationRow({required this.destination, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MessageRadius.bubble),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              destination.thumbnailAsset,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52,
                height: 52,
                color: MessageColors.tagBackground,
                child: const Icon(Icons.image_outlined, color: MessageColors.primaryGreen),
              ),
            ),
          ),
          const SizedBox(width: MessageSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        destination.name,
                        style: MessageTextStyles.destinationName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(destination.emoji, style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(destination.duration, style: MessageTextStyles.destinationDuration),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MessageSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: MessageColors.tagBackground,
              borderRadius: BorderRadius.circular(MessageRadius.pill),
            ),
            child: Text(destination.dayLabel, style: MessageTextStyles.dayTag),
          ),
          const SizedBox(width: MessageSpacing.sm),
          const Icon(Icons.chevron_right, size: 18, color: MessageColors.textGrey),
        ],
      ),
    );
  }
}
