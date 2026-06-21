import 'package:flutter/material.dart';
import 'package:assignment/screens/explore/screens/explore_screen.dart';
import 'package:assignment/screens/messages/messages_screen.dart';
import 'package:assignment/screens/profile/profile_screen.dart';
import 'package:assignment/screens/trips/screens/trip_planning_screen.dart';

import 'explore/screens/article_detail_screen.dart'; // IMPORT MỚI

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("Saved Screen")));
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 2; // Đặt là 2 để mặc định mở tab Trips

  static final List<Widget> _screens = [
    const ExploreScreen(),
    const SavedScreen(),
    const TripPlanningScreen(), // THAY THẾ Ở ĐÂY
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Giữ nguyên logic _buildBottomNav của bạn vì nó đã đẹp rồi
  Widget _buildBottomNav() {
    const activeColor = Color(0xFF2ECC71);
    const items = [
      _NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Explore'),
      _NavItem(icon: Icons.favorite_outline, activeIcon: Icons.favorite, label: 'Saved'),
      _NavItem(icon: Icons.luggage_outlined, activeIcon: Icons.luggage, label: 'Trips'),
      _NavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Messages'),
      _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = index == _currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          size: 22,
                          color: isActive ? activeColor : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? activeColor : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}