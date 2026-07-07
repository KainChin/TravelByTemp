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
  late List<_NavDockItem> _dockItems;

  @override
  void initState() {
    super.initState();
    _dockItems = [
      _NavDockItem(
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore,
        label: 'Khám phá',
        originalIndex: 0,
      ),
      _NavDockItem(
        icon: Icons.luggage_outlined,
        activeIcon: Icons.luggage,
        label: 'Chuyến đi',
        originalIndex: 1,
      ),
      _NavDockItem(
        icon: Icons.favorite_outline,
        activeIcon: Icons.favorite,
        label: 'Đã lưu',
        originalIndex: 2,
      ),
      _NavDockItem(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Tin nhắn',
        originalIndex: 3,
      ),
      _NavDockItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Tài khoản',
        originalIndex: 4,
      ),
    ];
  }

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
      extendBody: true, // Let stack flow transparently if needed
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 0), // Let content flow behind the floating dock
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SafeArea(
              child: _buildFloatingDock(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Apple-Style Floating Dock ──────────────────────────────────────────
  Widget _buildFloatingDock() {
    const activeColor = Color(0xFF0A84FF); // Bright iOS Blue
    const inactiveColor = Colors.white; // Solid white for maximum contrast and legibility

    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Increased blur for premium glass look
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.15), // Highly transparent dark glass
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: Colors.white.withOpacity(0.18), // Slightly lighter border
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_dockItems.length, (index) {
              final item = _dockItems[index];
              final isSelected = _currentIndex == item.originalIndex;

              final itemWidget = AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withOpacity(0.22) // Slightly richer active tint background
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
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
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, // Semi-bold for inactive text
                        color: isSelected ? activeColor : inactiveColor,
                      ),
                    ),
                  ],
                ),
              );

              return Expanded(
                child: DragTarget<_NavDockItem>(
                  onWillAccept: (draggedItem) {
                    if (draggedItem != null && draggedItem != item) {
                      final draggedIndex = _dockItems.indexOf(draggedItem);
                      final targetIndex = _dockItems.indexOf(item);
                      if (draggedIndex != -1 && targetIndex != -1) {
                        setState(() {
                          _dockItems.removeAt(draggedIndex);
                          _dockItems.insert(targetIndex, draggedItem);
                        });
                      }
                      return true;
                    }
                    return false;
                  },
                  onAccept: (draggedItem) {
                    // Reordering finalize
                  },
                  builder: (context, candidateData, rejectedData) {
                    return LongPressDraggable<_NavDockItem>(
                      data: item,
                      axis: Axis.horizontal,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Transform.scale(
                          scale: 1.2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isSelected ? item.activeIcon : item.icon,
                                  color: isSelected ? activeColor : inactiveColor,
                                  size: 24,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? activeColor : inactiveColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.25,
                        child: itemWidget,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _currentIndex = item.originalIndex;
                          if (item.originalIndex == 2) _savedRefreshToken++;
                          if (item.originalIndex == 4) _profileRefreshToken++;
                        }),
                        behavior: HitTestBehavior.opaque,
                        child: itemWidget,
                      ),
                    );
                  },
                ),
              );
            }),
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

class _NavDockItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int originalIndex;

  _NavDockItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.originalIndex,
  });
}
