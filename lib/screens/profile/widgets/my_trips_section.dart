import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/screens/trips/screens/trip_itinerary_history_screen.dart';
import 'package:assignment/screens/trips/screens/trip_itinerary_result_screen.dart';
import 'package:assignment/screens/trips/services/trip_itinerary_service.dart';
import 'package:flutter/material.dart';

class MyTripsSection extends StatefulWidget {
  const MyTripsSection({
    super.key,
    required this.refreshToken,
  });

  final int refreshToken;

  @override
  State<MyTripsSection> createState() => _MyTripsSectionState();
}

class _MyTripsSectionState extends State<MyTripsSection> {
  Future<List<TripItineraryHistoryItem>>? _future;
  String? _token;

  static const List<List<Color>> _cardGradients = [
    [Color(0xFF1A4870), Color(0xFF2D6EA0)],
    [Color(0xFF1A5E30), Color(0xFF2E8B50)],
    [Color(0xFF4A1060), Color(0xFF7B2E9A)],
    [Color(0xFF7A3000), Color(0xFFA84500)],
    [Color(0xFF005070), Color(0xFF007A90)],
    [Color(0xFF3A1A50), Color(0xFF6030A0)],
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = VietaiScope.of(context).auth?.accessToken;
    if (_future == null || token != _token) {
      _token = token;
      _future = _load(token);
    }
  }

  @override
  void didUpdateWidget(covariant MyTripsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _refresh();
    }
  }

  Future<List<TripItineraryHistoryItem>> _load(String? token) async {
    try {
      return await TripItineraryService(authToken: token).history();
    } catch (error, stackTrace) {
      debugPrint('[ProfileTrips] Could not load itinerary history: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  void _refresh() {
    setState(() {
      _future = _load(_token);
    });
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TripItineraryHistoryScreen()),
    ).then((_) => _refresh());
  }

  void _openTrip(TripItineraryHistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripItineraryResultScreen(
          response: 'Hanh trinh da luu',
          itinerary: item.itinerary,
          itineraryId: item.id,
        ),
      ),
    ).then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2540),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF243050), width: 1),
      ),
      child: Column(
        children: [
          _SectionHeader(onViewAll: _openHistory, onRefresh: _refresh),
          const SizedBox(height: 14),
          FutureBuilder<List<TripItineraryHistoryItem>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 128,
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF4CAF7A))),
                );
              }

              if (snapshot.hasError) {
                return _StateMessage(
                  icon: Icons.cloud_off_outlined,
                  title: 'Không tải được hành trình',
                  message: 'Kiểm tra kết nối rồi thử lại.',
                  actionLabel: 'Thử lại',
                  onAction: _refresh,
                );
              }

              final trips = snapshot.data ?? const [];
              if (trips.isEmpty) {
                return const _StateMessage(
                  icon: Icons.route_outlined,
                  title: 'Chưa có hành trình',
                  message: 'Những chuyến đi đã lưu sẽ hiện ở đây.',
                );
              }

              final visibleTrips = trips.take(4).toList();
              return SizedBox(
                height: 172,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visibleTrips.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, index) => SizedBox(
                    width: 180,
                    child: _TripCard(
                      trip: visibleTrips[index],
                      gradientColors: _cardGradients[index % _cardGradients.length],
                      onTap: () => _openTrip(visibleTrips[index]),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.onViewAll,
    required this.onRefresh,
  });

  final VoidCallback onViewAll;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.map_outlined, color: Color(0xFF4CAF7A), size: 20),
        const SizedBox(width: 6),
        const Text(
          'Chuyến đi của tôi',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onRefresh,
          child: const Icon(Icons.refresh_rounded, color: Color(0xFF4CAF7A), size: 18),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onViewAll,
          child: const Row(children: [
            Text(
              'Xem tất cả',
              style: TextStyle(fontSize: 13, color: Color(0xFF4CAF7A), fontWeight: FontWeight.w600),
            ),
            Icon(Icons.chevron_right, size: 16, color: Color(0xFF4CAF7A)),
          ]),
        ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.gradientColors,
    required this.onTap,
  });

  final TripItineraryHistoryItem trip;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final days = _dayCount(trip.itinerary);
    final activities = _activityCount(trip.itinerary);
    final date = _formatDate(trip.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Dark bottom overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top: date + bookmark
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          date,
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bookmark_border_rounded, color: Colors.white, size: 15),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Trip name
                  Text(
                    trip.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Stats row
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '$days ngày',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.explore_outlined, size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '$activities HĐ',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static int _dayCount(Map<String, dynamic> itinerary) {
    final days = itinerary['days'];
    if (days is List && days.isNotEmpty) return days.length;
    return 1;
  }

  static int _activityCount(Map<String, dynamic> itinerary) {
    final days = itinerary['days'];
    if (days is! List) return 0;
    var count = 0;
    for (final day in days) {
      if (day is Map<String, dynamic>) {
        final activities = day['activities'];
        if (activities is List) count += activities.length;
      }
    }
    return count;
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}

// ─────────────────────────────────────────────────────────────────

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF243050),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF304060)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4CAF7A)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: const TextStyle(color: Color(0xFF4CAF7A))),
            ),
        ],
      ),
    );
  }
}
