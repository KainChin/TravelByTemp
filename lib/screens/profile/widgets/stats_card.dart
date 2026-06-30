import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/screens/trips/services/trip_itinerary_service.dart';
import 'package:assignment/services/firestore_service.dart';
import 'package:flutter/material.dart';

class StatsCard extends StatefulWidget {
  const StatsCard({super.key});

  @override
  State<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard> {
  Future<_ProfileStats>? _future;
  String? _token;

  static const _iconColors = [
    Color(0xFF3A7D5A),
    Color(0xFF7B68EE),
    Color(0xFFE8624A),
    Color(0xFFF5A623),
  ];

  static const _bgColors = [
    Color(0xFFE8F5E9),
    Color(0xFFEDE7F6),
    Color(0xFFFFEBEE),
    Color(0xFFFFF3E0),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = VietaiScope.of(context).auth?.accessToken;
    if (_future == null || token != _token) {
      _token = token;
      _future = _loadStats();
    }
  }

  Future<_ProfileStats> _loadStats() async {
    final session = VietaiScope.of(context);
    final token = session.auth?.accessToken;

    final results = await Future.wait<dynamic>([
      _safe(() => TripItineraryService(authToken: token).history(), const <TripItineraryHistoryItem>[]),
      _safe(() => session.api.fetchFavorites(), const []),
      _safe(() => FirestoreService.getTrips().first, null),
      _safe(() => FirestoreService.getVideos().first, null),
    ]);

    final itineraries = results[0] as List<TripItineraryHistoryItem>;
    final favorites = results[1] as List;
    final tripsSnapshot = results[2];
    final videosSnapshot = results[3];

    var photos = 0;
    if (tripsSnapshot != null) {
      final docs = (tripsSnapshot as dynamic).docs as List;
      for (final doc in docs) {
        final data = doc.data();
        if (data is Map<String, dynamic>) {
          photos += (data['photoCount'] as num?)?.toInt() ?? 0;
        }
      }
    }

    final videos = videosSnapshot == null ? 0 : ((videosSnapshot as dynamic).docs as List).length;

    return _ProfileStats(
      trips: itineraries.length,
      photos: photos,
      videos: videos,
      places: favorites.length,
    );
  }

  Future<T> _safe<T>(Future<T> Function() load, T fallback) async {
    try {
      return await load();
    } catch (_) {
      return fallback;
    }
  }

  void _refresh() {
    setState(() => _future = _loadStats());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<_ProfileStats>(
        future: _future,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting;
          final stats = snapshot.data ?? _ProfileStats.zero;
          final items = [
            _StatConfig(Icons.luggage_outlined, loading ? '--' : '${stats.trips}', 'Trips'),
            _StatConfig(Icons.image_outlined, loading ? '--' : '${stats.photos}', 'Photos'),
            _StatConfig(Icons.video_library_outlined, loading ? '--' : '${stats.videos}', 'Videos'),
            _StatConfig(Icons.bookmark_outline, loading ? '--' : '${stats.places}', 'Places'),
          ];

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
              (index) => Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: snapshot.hasError ? _refresh : null,
                  child: _StatItem(
                    icon: items[index].icon,
                    value: items[index].value,
                    label: items[index].label,
                    iconColor: _iconColors[index],
                    bgColor: _bgColors[index],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileStats {
  const _ProfileStats({
    required this.trips,
    required this.photos,
    required this.videos,
    required this.places,
  });

  static const zero = _ProfileStats(trips: 0, photos: 0, videos: 0, places: 0);

  final int trips;
  final int photos;
  final int videos;
  final int places;
}

class _StatConfig {
  const _StatConfig(this.icon, this.value, this.label);

  final IconData icon;
  final String value;
  final String label;
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.bgColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF888888),
          ),
        ),
      ],
    );
  }
}
