import 'package:flutter/material.dart';
import 'package:assignment/screens/explore/screens/explore_screen.dart';
import 'package:assignment/screens/messages/messages_screen.dart';
import 'package:assignment/screens/profile/profile_screen.dart';
import 'package:assignment/screens/saved/saved_screen.dart';
import 'package:assignment/screens/trips/screens/trip_planning_screen.dart';


class MainShell extends StatefulWidget {
  /// Tên người dùng đã đăng nhập — truyền từ màn hình Login/Auth khi
  /// điều hướng tới MainShell, ví dụ:
  /// `Navigator.pushReplacement(context, MaterialPageRoute(
  ///   builder: (_) => MainShell(currentUserName: userModel.fullName),
  /// ));`
  final String currentUserName;

  const MainShell({super.key, required this.currentUserName});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0; // Open Explore/Home first after login.
  int _savedRefreshToken = 0;

  // Không còn là `static final` vì danh sách màn hình giờ phụ thuộc vào
  // currentUserName của widget (chỉ biết được ở instance, không phải static).
  List<Widget> get _screens => [
        const ExploreScreen(),
        SavedScreen(
          refreshToken: _savedRefreshToken,
          onHomePressed: () => setState(() => _currentIndex = 0),
        ),
        const TripPlanningScreen(),
        MessagesScreen(currentUserName: widget.currentUserName),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
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
                  onTap: () => setState(() {
                    _currentIndex = index;
                    if (index == 1) {
                      _savedRefreshToken++;
                    }
                  }),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
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


