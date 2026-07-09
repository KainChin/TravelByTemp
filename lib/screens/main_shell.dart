import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/screens/explore/screens/explore_screen.dart';
import 'package:assignment/screens/messages/messages_screen.dart';
import 'package:assignment/screens/profile/edit_profile_screen.dart';
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
  int _profileRefreshToken = 0;
  // Fixed nav items — order never changes
  static const _navItems = [
    (icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Khám phá', index: 0),
    (icon: Icons.luggage_outlined, activeIcon: Icons.luggage, label: 'Chuyến đi', index: 1),
    (icon: Icons.favorite_outline, activeIcon: Icons.favorite, label: 'Đã lưu', index: 2),
    (icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Tin nhắn', index: 3),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Tài khoản', index: 4),
  ];

  // Không còn là `static final` vì danh sách màn hình giờ phụ thuộc vào
  // currentUserName của widget (chỉ biết được ở instance, không phải static).
  List<Widget> get _screens => [
        ExploreScreen(
          onProfileTap: _openProfileTab,
          onSettingsTap: _openProfileSettings,
          onLogoutTap: _confirmLogout,
        ),
        const TripPlanningScreen(),
        SavedScreen(
          refreshToken: _savedRefreshToken,
          onHomePressed: () => setState(() => _currentIndex = 0),
        ),
        MessagesScreen(currentUserName: widget.currentUserName),
        ProfileScreen(refreshToken: _profileRefreshToken),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }


  Widget _buildBottomNav() {
    const activeColor = Color(0xFF0A84FF);
    const inactiveColor = Colors.white;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: EdgeInsets.only(
            left: 10,
            right: 10,
            bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 12,
            top: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.15),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.18),
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _navItems.map((item) {
              final isSelected = _currentIndex == item.index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _currentIndex = item.index;
                    if (item.index == 2) _savedRefreshToken++;
                    if (item.index == 4) _profileRefreshToken++;
                  }),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? activeColor.withOpacity(0.22)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected ? activeColor : inactiveColor,
                          size: 22,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? activeColor : inactiveColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _openProfileTab() {
    setState(() {
      _currentIndex = 4;
      _profileRefreshToken++;
    });
  }

  Future<void> _openProfileSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (!mounted) return;
    setState(() {
      _currentIndex = 4;
      _profileRefreshToken++;
    });
  }

  Future<void> _confirmLogout() async {
    final session = VietaiScope.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn muốn đăng xuất khỏi tài khoản hiện tại?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await session.logout();
  }
}

