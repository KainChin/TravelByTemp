import 'dart:convert';

import 'package:assignment/core/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/destination.dart';

class DestinationPickerSheet extends StatefulWidget {
  const DestinationPickerSheet({super.key});

  static Future<Destination?> show(BuildContext context) {
    return showModalBottomSheet<Destination>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DestinationPickerSheet(),
    );
  }

  @override
  State<DestinationPickerSheet> createState() => _DestinationPickerSheetState();
}

class _DestinationPickerSheetState extends State<DestinationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late final Future<List<Destination>> _destinationsFuture = _loadDestinations();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd');

  bool _matches(Destination destination) {
    if (_query.trim().isEmpty) return true;
    final query = _normalize(_query);
    final haystack = _normalize(
      '${destination.name} ${destination.region} ${destination.highlight}',
    );
    return haystack.contains(query);
  }

  Future<List<Destination>> _loadDestinations() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/destinations'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Cannot load destinations from backend.');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) return const [];

    return decoded.whereType<Map<String, dynamic>>().map((json) {
      return Destination(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        region: json['region'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        highlight: json['province'] as String? ??
            json['category'] as String? ??
            json['description'] as String? ??
            '',
      );
    }).where((destination) {
      return destination.id.isNotEmpty &&
          destination.name.isNotEmpty &&
          destination.latitude != 0 &&
          destination.longitude != 0;
    }).toList();
  }

  Map<String, List<Destination>> _groupByRegion(List<Destination> destinations) {
    final grouped = <String, List<Destination>>{};
    for (final destination in destinations.where(_matches)) {
      final region = destination.region.isEmpty ? 'Other' : destination.region;
      grouped.putIfAbsent(region, () => []).add(destination);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF7FAF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4DED8),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn điểm đến',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Tìm tỉnh, thành phố, điểm nổi bật...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Destination>>(
                  future: _destinationsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Khong tai duoc danh sach diem den.'),
                        ),
                      );
                    }

                    final grouped = _groupByRegion(snapshot.data ?? const []);
                    if (grouped.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Khong co diem den phu hop.'),
                        ),
                      );
                    }

                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: grouped.entries.map((entry) {
                        return _RegionSection(
                          region: entry.key,
                          destinations: entry.value,
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RegionSection extends StatelessWidget {
  const _RegionSection({required this.region, required this.destinations});

  final String region;
  final List<Destination> destinations;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              region,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF0B7D4B),
                fontSize: 14,
              ),
            ),
          ),
          ...destinations.map((destination) => _DestinationTile(destination)),
        ],
      ),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile(this.destination);

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(destination),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F4E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.place_outlined, color: Color(0xFF0FA958)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (destination.highlight.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          destination.highlight,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF647067),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF9AA7A0)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
