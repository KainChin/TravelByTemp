import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/screens/trips/services/trip_itinerary_service.dart';
import 'package:assignment/services/api_client.dart';
import 'package:assignment/services/firestore_service.dart';
import 'package:flutter/material.dart';

class StatsCard extends StatefulWidget {
  const StatsCard({
    super.key,
    required this.refreshToken,
  });

  final int refreshToken;

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

  @override
  void didUpdateWidget(covariant StatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _refresh();
    }
  }

  Future<_ProfileStats> _loadStats() async {
    final session = VietaiScope.of(context);
    try {
      final summary = await session.api.fetchProfileSummary();
      return _ProfileStats(
        trips: summary.trips,
        photos: summary.photos,
        videos: summary.videos,
        places: summary.savedPlaces,
      );
    } on ApiException catch (error, stackTrace) {
      if (error.statusCode != 404) {
        debugPrint('[ProfileStats] Failed to load /api/profile/summary: $error');
        debugPrintStack(stackTrace: stackTrace);
        rethrow;
      }
      debugPrint('[ProfileStats] /api/profile/summary is not available. Falling back to existing data sources.');
      return _loadFallbackStats(session.auth?.accessToken);
    } catch (error, stackTrace) {
      debugPrint('[ProfileStats] Unexpected error while loading profile summary: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<_ProfileStats> _loadFallbackStats(String? token) async {
    final results = await Future.wait<Object>([
      _safeCount('itinerary history', () async {
        return TripItineraryService(authToken: token).history().then((items) => items.length);
      }),
      _safeCount('favorites', () async {
        return VietaiScope.of(context).api.fetchFavorites().then((items) => items.length);
      }),
      _safeCount('Firestore trips', _countFirestoreTrips),
      _safeCount('Firestore videos', _countFirestoreVideos),
    ]);

    final itineraryTrips = results[0] as int;
    final places = results[1] as int;
    final firestore = results[2] as _FirestoreTripCount;
    final videos = results[3] as int;

    return _ProfileStats(
      trips: itineraryTrips > firestore.trips ? itineraryTrips : firestore.trips,
      photos: firestore.photos,
      videos: videos,
      places: places,
    );
  }

  Future<T> _safeCount<T>(String source, Future<T> Function() load) async {
    try {
      return await load();
    } catch (error, stackTrace) {
      debugPrint('[ProfileStats] Could not load $source: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (T == _FirestoreTripCount) {
        return const _FirestoreTripCount(trips: 0, photos: 0) as T;
      }
      return 0 as T;
    }
  }

  Future<_FirestoreTripCount> _countFirestoreTrips() async {
    final snapshot = await FirestoreService.getTrips().first.timeout(const Duration(seconds: 5));
    var photos = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data is Map<String, dynamic>) {
        photos += (data['photoCount'] as num?)?.toInt() ?? 0;
      }
    }
    return _FirestoreTripCount(trips: snapshot.docs.length, photos: photos);
  }

  Future<int> _countFirestoreVideos() async {
    final snapshot = await FirestoreService.getVideos().first.timeout(const Duration(seconds: 5));
    return snapshot.docs.length;
  }

  void _refresh() {
    setState(() {
      _future = _loadStats();
    });
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

class _FirestoreTripCount {
  const _FirestoreTripCount({
    required this.trips,
    required this.photos,
  });

  final int trips;
  final int photos;
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
