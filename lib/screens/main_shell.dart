import 'package:flutter/material.dart';
import 'package:assignment/core/widgets/app_bottom_nav.dart';
import 'package:assignment/screens/explore/explore_screen.dart';
import 'package:assignment/screens/messages/messages_screen.dart';
import 'package:assignment/screens/profile/profile_screen.dart';
import 'package:assignment/screens/saved/saved_screen.dart';
import 'package:assignment/screens/trips/ai_itinerary_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  NavTab _current = NavTab.explore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _current.index,
        children: const [
          ExploreScreen(),
          SavedScreen(),
          AiItineraryScreen(),
          MessagesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        current: _current,
        onTap: (tab) => setState(() => _current = tab),
      ),
    );
  }
}
