import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'create_trip_screen.dart';
import 'trip_itinerary_history_screen.dart';
import 'trip_planning/trip_tokens.dart';
import 'trip_planning/trip_shared_widgets.dart';
import 'trip_planning/trip_hero_card.dart';
import 'trip_planning/trip_search_bar.dart';
import 'trip_planning/trip_quick_actions.dart';
import 'trip_planning/trip_ai_insight_card.dart';
import 'trip_planning/trip_recent_section.dart';
import 'trip_planning/trip_inspiration_card.dart';

class TripPlanningScreen extends StatelessWidget {
  const TripPlanningScreen({super.key});

  void _goCreate(BuildContext ctx) => Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => const CreateTripScreen()),
      );

  void _goHistory(BuildContext ctx) => Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => const TripItineraryHistoryScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final hPad = tripHPadding(context);

    return Scaffold(
      backgroundColor: kTripBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _responsive(
                  context,
                  child: tripIsDesktop(context)
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _HomeMainContent(
                                onCreate: () => _goCreate(context),
                                onHistory: () => _goHistory(context),
                              ),
                            ),
                            const SizedBox(width: 28),
                            SizedBox(
                              width: 360,
                              child: _HomeSidebar(
                                onCreate: () => _goCreate(context),
                              ),
                            ),
                          ],
                        )
                      : _HomeMainContent(
                          onCreate: () => _goCreate(context),
                          onHistory: () => _goHistory(context),
                        ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _responsive(BuildContext context, {required Widget child}) {
    final maxW = tripMaxWidth(context);
    if (maxW == double.infinity) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: child,
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: kTripBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'Trips',
        style: TextStyle(
          color: kTripInk,
          fontWeight: FontWeight.w900,
          fontSize: 22,
        ),
      ),
      actions: [
        TripGradIconBtn(
          icon: Icons.history_rounded,
          gradient: kGradPrimary,
          onTap: () => _goHistory(context),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

class _HomeMainContent extends StatelessWidget {
  const _HomeMainContent({
    required this.onCreate,
    required this.onHistory,
  });

  final VoidCallback onCreate;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final showInlineInsight = !tripIsDesktop(context);
    return Column(
      children: [
        TripHeroCard(onCreate: onCreate)
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(begin: const Offset(0.97, 0.97), curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        TripSearchBar(onTap: onCreate)
            .animate()
            .fadeIn(delay: 100.ms, duration: 500.ms)
            .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
        const SizedBox(height: 20),
        TripQuickActions(onCreate: onCreate, onHistory: onHistory)
            .animate()
            .fadeIn(delay: 180.ms, duration: 500.ms)
            .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
        if (showInlineInsight) ...[
          const SizedBox(height: 24),
          TripAiInsightCard(onCreate: onCreate)
              .animate()
              .fadeIn(delay: 260.ms, duration: 600.ms)
              .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
        ],
        const SizedBox(height: 28),
        TripSectionHeader(
          title: 'Gan day',
          action: 'Xem tat ca',
          onAction: onHistory,
        ).animate().fadeIn(delay: 340.ms),
        const SizedBox(height: 14),
        TripRecentSection(onCreate: onCreate)
            .animate()
            .fadeIn(delay: 400.ms, duration: 600.ms)
            .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
        const SizedBox(height: 28),
        const TripSectionHeader(title: 'AI Recommendation')
            .animate()
            .fadeIn(delay: 460.ms),
        const SizedBox(height: 14),
        TripInspirationCard(onCreate: onCreate)
            .animate()
            .fadeIn(delay: 520.ms, duration: 600.ms)
            .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
      ],
    );
  }
}

class _HomeSidebar extends StatelessWidget {
  const _HomeSidebar({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TripAiInsightCard(onCreate: onCreate)
            .animate()
            .fadeIn(delay: 220.ms, duration: 500.ms)
            .slideX(begin: 0.04, end: 0, curve: Curves.easeOut),
        const SizedBox(height: 16),
        const _SidebarStatsCard(),
        const SizedBox(height: 16),
        const _SidebarWeatherCard(),
        const SizedBox(height: 16),
        const _SidebarListCard(
          title: 'Trending Destinations',
          icon: Icons.local_fire_department_rounded,
          items: [
            _SidebarListItem(
              'Da Lat',
              'Cool weather, +28% searches',
              Icons.trending_up_rounded,
            ),
            _SidebarListItem(
              'Phu Quoc',
              'Beach season, 4.8 rating',
              Icons.beach_access_rounded,
            ),
            _SidebarListItem(
              'Ha Giang',
              'Popular 3-day routes',
              Icons.terrain_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _SidebarListCard(
          title: 'Recent Activity',
          icon: Icons.history_rounded,
          items: [
            _SidebarListItem(
              'AI route checked',
              '2 minutes ago',
              Icons.auto_awesome_rounded,
            ),
            _SidebarListItem(
              'Budget updated',
              'Estimated saving 12%',
              Icons.savings_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _TravelTipCard(),
      ],
    );
  }
}

class _SidebarStatsCard extends StatelessWidget {
  const _SidebarStatsCard();

  @override
  Widget build(BuildContext context) {
    return _SidebarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SidebarTitle(icon: Icons.insights_rounded, title: 'Quick Statistics'),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _MetricTile(value: '92', label: 'AI score')),
              SizedBox(width: 10),
              Expanded(child: _MetricTile(value: '15%', label: 'Savings')),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MetricTile(value: '4.8', label: 'Rating')),
              SizedBox(width: 10),
              Expanded(child: _MetricTile(value: '3N2D', label: 'Top trip')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarWeatherCard extends StatelessWidget {
  const _SidebarWeatherCard();

  @override
  Widget build(BuildContext context) {
    return _SidebarCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: kTripAmber.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.wb_sunny_rounded, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather Window',
                  style: TextStyle(
                    color: kTripInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Da Lat 18-24C, low rain risk',
                  style: TextStyle(color: kTripMuted, fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
          const Text(
            'Good',
            style: TextStyle(
              color: kTripPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarListCard extends StatelessWidget {
  const _SidebarListCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<_SidebarListItem> items;

  @override
  Widget build(BuildContext context) {
    return _SidebarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SidebarTitle(icon: icon, title: title),
          const SizedBox(height: 12),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: kTripPrimary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(item.icon, size: 17, color: kTripPrimary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: kTripInk,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: kTripMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SidebarListItem {
  const _SidebarListItem(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}

class _TravelTipCard extends StatelessWidget {
  const _TravelTipCard();

  @override
  Widget build(BuildContext context) {
    return _SidebarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SidebarTitle(icon: Icons.tips_and_updates_rounded, title: 'Travel Tip'),
          SizedBox(height: 10),
          Text(
            'Book weekday departures for beach trips. AI usually finds lower fares and quieter hotels.',
            style: TextStyle(color: kTripMuted, fontSize: 12, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kTripPrimary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: kTripInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: kTripMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTitle extends StatelessWidget {
  const _SidebarTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: kTripPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: kTripInk,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SidebarCard extends StatelessWidget {
  const _SidebarCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kTripLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x070F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
