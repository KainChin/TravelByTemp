import 'package:flutter/material.dart';

import '../models/destination.dart';

/// Một dòng trong "Danh sách điểm đến": số thứ tự tròn xanh, tên điểm đến,
/// phụ đề khoảng cách, và nút xoá (nếu [onRemove] được cung cấp).
class DestinationListItem extends StatelessWidget {
  final int order;
  final SelectedDestination item;
  final VoidCallback? onRemove;

  const DestinationListItem({
    super.key,
    required this.order,
    required this.item,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _OrderBadge(order: order),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.destination.name,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  item.subtitleLabel,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: Colors.grey.shade500,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

class _OrderBadge extends StatelessWidget {
  final int order;

  const _OrderBadge({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF0FA958),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$order',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}