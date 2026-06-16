import 'package:flutter/material.dart';
import 'explore/explore_screen.dart';
import 'package:assignment/screens/messages/messages_screen.dart';
import 'package:assignment/screens/profile/profile_screen.dart';
import 'package:assignment/screens/trips/screens/trips_screen.dart';
// ─── Placeholder screens ──────────────────────────────────
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      _PlaceholderScreen(icon: Icons.favorite_outline, label: 'Saved', color: Colors.red);
}

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      _PlaceholderScreen(icon: Icons.luggage_outlined, label: 'Trips', color: const Color(0xFF2ECC71));
}



class _PlaceholderScreen extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _PlaceholderScreen({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(label,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text('Coming soon...',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

// ─── Main Shell ───────────────────────────────────────────
// KHÔNG có MultiProvider ở đây — provider đã được đặt ở main.dart
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Dùng static final để list không tạo lại mỗi lần build
  static final List<Widget> _screens = [
    const ExploreScreen(),
    const SavedScreen(),
    const TripsScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Chỉ có Scaffold — không wrap MultiProvider ở đây
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      _NavItem(icon: Icons.explore_outlined,   activeIcon: Icons.explore,    label: 'Explore'),
      _NavItem(icon: Icons.favorite_outline,    activeIcon: Icons.favorite,   label: 'Saved'),
      _NavItem(icon: Icons.luggage_outlined,    activeIcon: Icons.luggage,    label: 'Trips'),
      _NavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble,label: 'Messages'),
      _NavItem(icon: Icons.person_outline,      activeIcon: Icons.person,     label: 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
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
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _currentIndex = index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF2ECC71).withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          size: 22,
                          color: isActive
                              ? const Color(0xFF2ECC71)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? const Color(0xFF2ECC71)
                              : const Color(0xFF9CA3AF),
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
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}
