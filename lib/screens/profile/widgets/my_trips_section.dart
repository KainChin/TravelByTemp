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
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _SectionHeader(onViewAll: _openHistory, onRefresh: _refresh),
          const SizedBox(height: 12),
          FutureBuilder<List<TripItineraryHistoryItem>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 128,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return _StateMessage(
                  icon: Icons.cloud_off_outlined,
                  title: 'Khong tai duoc hanh trinh',
                  message: 'Kiem tra ket noi backend roi thu lai.',
                  actionLabel: 'Thu lai',
                  onAction: _refresh,
                );
              }

              final trips = snapshot.data ?? const [];
              if (trips.isEmpty) {
                return const _StateMessage(
                  icon: Icons.route_outlined,
                  title: 'Chua co hanh trinh',
                  message: 'Nhung chuyen di da luu se hien o day.',
                );
              }

              final visibleTrips = trips.take(6).toList();
              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 680) {
                    final cardWidth = constraints.maxWidth >= 980 ? 210.0 : 190.0;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final trip in visibleTrips)
                          SizedBox(
                            width: cardWidth,
                            child: _TripCard(
                              trip: trip,
                              onTap: () => _openTrip(trip),
                            ),
                          ),
                      ],
                    );
                  }

                  return SizedBox(
                    height: 172,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: visibleTrips.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (_, index) => SizedBox(
                        width: 176,
                        child: _TripCard(
                          trip: visibleTrips[index],
                          onTap: () => _openTrip(visibleTrips[index]),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.onViewAll,
    required this.onRefresh,
  });

  final VoidCallback onViewAll;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.map_outlined, color: colors.primary, size: 20),
        const SizedBox(width: 6),
        const Text(
          'Hanh trinh cua toi',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Tai lai',
          visualDensity: VisualDensity.compact,
          onPressed: onRefresh,
          icon: Icon(Icons.refresh_rounded, color: colors.primary, size: 18),
        ),
        TextButton.icon(
          onPressed: onViewAll,
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.chevron_right, size: 16),
          label: const Text('Xem tat ca'),
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.onTap,
  });

  final TripItineraryHistoryItem trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final days = _dayCount(trip.itinerary);
    final activities = _activityCount(trip.itinerary);
    final date = _formatDate(trip.createdAt);

    return Material(
      color: colors.primaryContainer.withValues(alpha: 0.38),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.route_rounded, color: colors.primary, size: 19),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                trip.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _MiniChip(label: '$days ngay', icon: Icons.calendar_today_outlined),
                  _MiniChip(label: '$activities hoat dong', icon: Icons.explore_outlined),
                ],
              ),
            ],
          ),
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

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: colors.primary),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
