import 'package:assignment/core/utils/destination_images.dart';
import 'package:assignment/core/widgets/safe_network_image.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/trip_itinerary_service.dart';
import 'trip_itinerary_result_screen.dart';

// ─── Tokens ──────────────────────────────────────────────────────────────────
const _bg = Color(0xFFF8F9FA);
const _ink = Color(0xFF1A1F36);
const _muted = Color(0xFF6B7280);
const _line = Color(0xFFE5E7EB);
const _indigo = Color(0xFF4338CA);
const _teal = Color(0xFF0D9488);

class TripItineraryHistoryScreen extends StatefulWidget {
  const TripItineraryHistoryScreen({super.key});

  @override
  State<TripItineraryHistoryScreen> createState() => _TripItineraryHistoryScreenState();
}

class _TripItineraryHistoryScreenState extends State<TripItineraryHistoryScreen> {
  late Future<List<TripItineraryHistoryItem>> _future;
  bool _init = false;
  String? _token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _token = VietaiScope.of(context).auth?.accessToken;
    _future = TripItineraryService(authToken: _token).history();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = TripItineraryService(authToken: _token).history();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _ink,
        title: const Text('Lịch sử hành trình',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4338CA), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<TripItineraryHistoryItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 48, height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4338CA)),
                    backgroundColor: _indigo.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Đang tải...', style: TextStyle(color: _muted, fontWeight: FontWeight.w600)),
              ]),
            );
          }

          if (snap.hasError) {
            return _StateCard(
              icon: Icons.cloud_off_rounded,
              title: 'Chưa tải được lịch sử',
              message: '${snap.error}',
              onRetry: _refresh,
            );
          }

          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return _StateCard(
              icon: Icons.route_rounded,
              title: 'Chưa có hành trình',
              message: 'Các chuyến đi đã tạo sẽ xuất hiện tại đây.',
              onRetry: _refresh,
            );
          }

          return RefreshIndicator(
            color: _indigo,
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return _HistoryCard(
                  item: item,
                  index: i,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => TripItineraryResultScreen(
                      response: 'Hành trình đã lưu',
                      itinerary: item.itinerary,
                      itineraryId: item.id,
                    ),
                  )),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── History Card ─────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, required this.index, required this.onTap});
  final TripItineraryHistoryItem item;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final days = item.itinerary['days'] is List ? (item.itinerary['days'] as List).length : 0;
    final date = '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}';

    // Try to extract destination info from itinerary for cover image.
    final destinations = _extractDestinations(item.itinerary);
    final coverUrl = destinations.isEmpty ? null : _coverUrlFor(destinations.first);
    final activityCount = destinations.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _line),
          boxShadow: const [BoxShadow(color: Color(0x080F172A), blurRadius: 16, offset: Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover image (with shimmer + gradient fallback)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SafeNetworkImage(
                    url: coverUrl,
                    fit: BoxFit.cover,
                    source: 'history-card-${item.id}',
                    fallback: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: index % 2 == 0
                              ? const [Color(0xFF4338CA), Color(0xFF6D28D9)]
                              : const [Color(0xFF0D9488), Color(0xFF0891B2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        // Decorative route/network background
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.alt_route_rounded,
                            color: Colors.white.withValues(alpha: 0.18),
                            size: 90,
                          ),
                          if (destinations.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: Text(
                                destinations.take(3).join(' • '),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Subtle dark gradient for top/bottom chips readability.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Top-left chip: number of activities
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.place_rounded, size: 12, color: _indigo),
                          const SizedBox(width: 4),
                          Text(
                            '$activityCount điểm',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _indigo,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom-left: trip title on cover
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        shadows: [
                          Shadow(color: Color(0x88000000), blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info row: meta chips
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MetaTag(icon: Icons.calendar_today_outlined, label: date, color: _muted),
                      if (days > 0)
                        _MetaTag(
                          icon: Icons.event_outlined,
                          label: '$days ngày',
                          color: _indigo,
                        ),
                      if (item.aiModel != null && item.aiModel!.trim().isNotEmpty)
                        _MetaTag(
                          icon: Icons.smart_toy_outlined,
                          label: item.aiModel!,
                          color: _teal,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Nhấn để xem chi tiết chuyến đi',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _indigo.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: _indigo,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(delay: (index * 80).ms)
          .fadeIn(duration: 500.ms)
          .slideX(begin: 0.08, end: 0, curve: Curves.easeOut),
    );
  }

  // Extract a list of destination names from itinerary days/activities.
  static List<String> _extractDestinations(Map<String, dynamic> itinerary) {
    final names = <String>{};
    final days = itinerary['days'];
    if (days is List) {
      for (final day in days) {
        if (day is Map) {
          final activities = day['activities'];
          if (activities is List) {
            for (final a in activities) {
              if (a is Map) {
                final d = (a['destination'] ?? a['placeName'] ?? '').toString().trim();
                if (d.isNotEmpty && d.toLowerCase() != 'null') {
                  names.add(d);
                  if (names.length >= 6) return names.toList();
                }
              }
            }
          }
        }
      }
    }
    // Fallback: try destinations/places at root.
    final root = itinerary['destinations'] ?? itinerary['places'];
    if (root is List) {
      for (final p in root) {
        if (p is Map) {
          final n = (p['name'] ?? p['destination'] ?? '').toString().trim();
          if (n.isNotEmpty && n.toLowerCase() != 'null') {
            names.add(n);
            if (names.length >= 6) return names.toList();
          }
        }
      }
    }
    return names.toList();
  }

  // Build Unsplash cover URL from destination name (use seed for stable image).
  static String? _coverUrlFor(String destinationName) {
    final query = DestinationImages.urlFor(destinationName);
    return query.startsWith('http') ? query : null;
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    ]);
  }
}

// ─── State Card ───────────────────────────────────────────────────────────────
class _StateCard extends StatelessWidget {
  const _StateCard({required this.icon, required this.title, required this.message, required this.onRetry});
  final IconData icon;
  final String title, message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _indigo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 36, color: _indigo.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 18),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ink)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _muted, height: 1.5)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF4338CA), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.refresh_rounded, color: Colors.white, size: 15),
                SizedBox(width: 6),
                Text('Tải lại', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
