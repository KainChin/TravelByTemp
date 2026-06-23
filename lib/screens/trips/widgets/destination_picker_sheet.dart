import 'package:flutter/material.dart';

import '../models/destination.dart';

/// Bottom sheet cho phép người dùng chọn 1 điểm đến, các điểm được
/// gom nhóm hiển thị theo miền (Miền Bắc, Miền Trung, Miền Nam, Miền Tây).
class DestinationPickerSheet extends StatelessWidget {
  const DestinationPickerSheet({super.key});

  /// Helper mở bottom sheet và trả về [Destination] người dùng chọn,
  /// hoặc null nếu họ đóng sheet mà không chọn gì.
  static Future<Destination?> show(BuildContext context) {
    return showModalBottomSheet<Destination>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const DestinationPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chọn điểm đến',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: DestinationCatalog.regionOrder
                    .map((region) => _RegionSection(
                  region: region,
                  destinations: DestinationCatalog.byRegion[region]!,
                ))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RegionSection extends StatelessWidget {
  final String region;
  final List<Destination> destinations;

  const _RegionSection({required this.region, required this.destinations});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            region,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ),
        ...destinations.map(
              (d) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_on_outlined,
                color: Color(0xFF0FA958)),
            title: Text(d.name),
            onTap: () => Navigator.of(context).pop(d),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}