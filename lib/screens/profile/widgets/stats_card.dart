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
    Color(0xFF4CAF7A),
    Color(0xFF9C88FF),
    Color(0xFFEF5350),
    Color(0xFFFFB74D),
  ];

  static const _bgColors = [
    Color(0xFF1B3D2A),
    Color(0xFF2D2660),
    Color(0xFF3D1A1A),
    Color(0xFF3D2800),
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
    setState(() => _future = _loadStats());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FutureBuilder<_ProfileStats>(
        future: _future,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting;
          final stats = snapshot.data ?? _ProfileStats.zero;
          final items = [
            _StatConfig(Icons.luggage_outlined, loading ? '--' : '${stats.trips}', 'Chuyến đi', _iconColors[0], _bgColors[0]),
            _StatConfig(Icons.image_outlined, loading ? '--' : '${stats.photos}', 'Ảnh đã lưu', _iconColors[1], _bgColors[1]),
            _StatConfig(Icons.video_library_outlined, loading ? '--' : '${stats.videos}', 'Video đã lưu', _iconColors[2], _bgColors[2]),
            _StatConfig(Icons.location_on_outlined, loading ? '--' : '${stats.places}', 'Địa điểm đã đến', _iconColors[3], _bgColors[3]),
          ];

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatItem(item: items[0], onTap: snapshot.hasError ? _refresh : null),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatItem(item: items[1], onTap: snapshot.hasError ? _refresh : null),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(item: items[2], onTap: snapshot.hasError ? _refresh : null),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatItem(item: items[3], onTap: snapshot.hasError ? _refresh : null),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────

class _FirestoreTripCount {
  const _FirestoreTripCount({required this.trips, required this.photos});
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
  const _StatConfig(this.icon, this.value, this.label, this.iconColor, this.bgColor);
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color bgColor;
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.item, this.onTap});
  final _StatConfig item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A2540),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF243050), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 22, color: item.iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Colors.white54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
