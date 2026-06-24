import 'package:flutter/material.dart';

import '../services/trip_itinerary_service.dart';
import 'trip_itinerary_result_screen.dart';

class TripItineraryHistoryScreen extends StatefulWidget {
  const TripItineraryHistoryScreen({super.key});

  @override
  State<TripItineraryHistoryScreen> createState() =>
      _TripItineraryHistoryScreenState();
}

class _TripItineraryHistoryScreenState
    extends State<TripItineraryHistoryScreen> {
  late Future<List<TripItineraryHistoryItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = TripItineraryService().history();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = TripItineraryService().history();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Itinerary history'),
      ),
      body: FutureBuilder<List<TripItineraryHistoryItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0FA958)),
            );
          }

          if (snapshot.hasError) {
            return _StateMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Cannot load history',
              message: '${snapshot.error}',
              action: _refresh,
            );
          }

          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return _StateMessage(
              icon: Icons.route_outlined,
              title: 'No itineraries yet',
              message: 'Generated trips will appear here.',
              action: _refresh,
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF0FA958),
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _HistoryTile(
                  item: item,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripItineraryResultScreen(
                          response: 'Saved itinerary',
                          itinerary: item.itinerary,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item, required this.onTap});

  final TripItineraryHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date =
        '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}';
    final days = item.itinerary['days'] is List
        ? (item.itinerary['days'] as List).length
        : 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8E4)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF0FA958),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$date • $days days • ${item.aiModel ?? 'AI'}',
                      style: const TextStyle(
                        color: Color(0xFF647067),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF8A948D)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function() action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF8A948D)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF647067)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: action,
              icon: const Icon(Icons.refresh, color: Color(0xFF0FA958)),
              label: const Text(
                'Refresh',
                style: TextStyle(color: Color(0xFF0FA958)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
