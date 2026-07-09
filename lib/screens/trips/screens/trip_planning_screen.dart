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
import 'trip_planning/trip_home_sidebar.dart';

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
                              child: HomeSidebar(
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

// The rest of the file has been moved to trip_home_sidebar.dart
