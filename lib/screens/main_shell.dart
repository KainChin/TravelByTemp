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

  // Không còn là `static final` vì danh sách màn hình giờ phụ thuộc vào
  // currentUserName của widget (chỉ biết được ở instance, không phải static).
  List<Widget> get _screens => [
        ExploreScreen(
          onProfileTap: _openProfileTab,
          onSettingsTap: _openProfileSettings,
          onLogoutTap: _confirmLogout,
        ),
        SavedScreen(
          refreshToken: _savedRefreshToken,
          onHomePressed: () => setState(() => _currentIndex = 0),
        ),
        const TripPlanningScreen(),
        MessagesScreen(currentUserName: widget.currentUserName),
        ProfileScreen(refreshToken: _profileRefreshToken),
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

  // ── Material 3 Bottom Navigation ──────────────────────────────────────────
  Widget _buildBottomNav() {
    const activeColor = Color(0xFF2ECC71);
    const inactiveColor = Color(0xFF9CA3AF);

    return NavigationBar(
      height: 68,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black26,
      indicatorColor: activeColor.withValues(alpha: 0.12),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      animationDuration: const Duration(milliseconds: 400),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() {
        _currentIndex = index;
        if (index == 1) _savedRefreshToken++;
        if (index == 4) _profileRefreshToken++;
      }),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.explore_outlined, color: inactiveColor, size: 22),
          selectedIcon: Icon(Icons.explore, color: activeColor, size: 22),
          label: 'Explore',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_outline, color: inactiveColor, size: 22),
          selectedIcon: Icon(Icons.favorite, color: activeColor, size: 22),
          label: 'Saved',
        ),
        NavigationDestination(
          icon: Icon(Icons.luggage_outlined, color: inactiveColor, size: 22),
          selectedIcon: Icon(Icons.luggage, color: activeColor, size: 22),
          label: 'Trips',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline, color: inactiveColor, size: 22),
          selectedIcon: Icon(Icons.chat_bubble, color: activeColor, size: 22),
          label: 'Messages',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline, color: inactiveColor, size: 22),
          selectedIcon: Icon(Icons.person, color: activeColor, size: 22),
          label: 'Profile',
        ),
      ],
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
