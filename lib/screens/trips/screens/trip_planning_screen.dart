import 'package:flutter/material.dart';

import 'create_trip_screen.dart';
import 'trip_itinerary_history_screen.dart';
import 'trip_planning/dashboard/dashboard_page.dart';

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
    return PremiumDashboardPage(
      onCreateTrip: () => _goCreate(context),
      onHistory: () => _goHistory(context),
    );
  }
}
