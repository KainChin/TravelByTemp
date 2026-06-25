import 'package:flutter/material.dart';

import 'create_trip_screen.dart';
import 'trip_itinerary_history_screen.dart';

class TripPlanningScreen extends StatelessWidget {
  const TripPlanningScreen({super.key});

  static const _bg = Color(0xFFF5F7F4);
  static const _ink = Color(0xFF15221D);
  static const _muted = Color(0xFF6E7A74);
  static const _primary = Color(0xFF008F6A);
  static const _accent = Color(0xFFFF8A5B);
  static const _line = Color(0xFFE2E8E4);

  void _openCreateTrip(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTripScreen()),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TripItineraryHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: _bg,
              surfaceTintColor: _bg,
              elevation: 0,
              title: const Text(
                'Trips',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
              ),
              actions: [
                IconButton(
                  tooltip: 'Lịch sử',
                  onPressed: () => _openHistory(context),
                  icon: const Icon(Icons.history_rounded, color: _ink),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _HeroCard(onCreate: () => _openCreateTrip(context)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.add_location_alt_outlined,
                          title: 'Tạo chuyến mới',
                          subtitle: 'Chọn nhiều điểm đến',
                          color: _primary,
                          onTap: () => _openCreateTrip(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.auto_awesome_outlined,
                          title: 'Lịch AI',
                          subtitle: 'Xem lịch đã tạo',
                          color: _accent,
                          onTap: () => _openHistory(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Gần đây',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _EmptyState(onCreate: () => _openCreateTrip(context)),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () => _openCreateTrip(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tạo hành trình mới'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: TripPlanningScreen._primary,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1100&q=80',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xDD06251E), Color(0x3306251E)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'AI Travel Planner',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Thiết kế chuyến đi\ntrong vài phút',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Phân tích tuyến đường, phương tiện và tạo lịch trình theo ngân sách.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TripPlanningScreen._line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: TripPlanningScreen._ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: TripPlanningScreen._muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TripPlanningScreen._line),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F6F0),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.luggage_outlined,
              color: TripPlanningScreen._primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có hành trình nào',
            style: TextStyle(
              color: TripPlanningScreen._ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bắt đầu bằng cách chọn điểm đến, ngày ở lại và ngân sách. AI sẽ giúp bạn dựng tuyến đi hợp lý.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TripPlanningScreen._muted,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
