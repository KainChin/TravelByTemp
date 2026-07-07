import 'package:flutter/material.dart';

class ProfileSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const ProfileSidebar({
    super.key,
    this.selectedIndex = 0,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: const Color(0xFF0B1120), // Very dark navy-blue panel
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildMenuItem(0, Icons.shield_outlined, 'Tổng quan'),
                _buildMenuItem(1, Icons.luggage, 'Chuyến đi của tôi'),
                _buildMenuItem(2, Icons.bookmark_outline, 'Bộ sưu tập'),
                _buildMenuItem(3, Icons.play_circle_outline, 'Video của tôi'),
                _buildMenuItem(4, Icons.auto_stories, 'Kỷ niệm (Story)'),
                _buildMenuItem(5, Icons.star_border, 'Đánh giá của tôi'),
                _buildMenuItem(6, Icons.settings_outlined, 'Cài đặt tài khoản'),
              ],
            ),
          ),
          _buildBottomCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Row(
        children: [
          // Logo (shield with a compass inside)
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.shield, color: Colors.white.withValues(alpha:0.1), size: 36),
              const Icon(Icons.explore, color: Colors.white, size: 22),
            ],
          ),
          const SizedBox(width: 12),
          const Text(
            'VietAI Travel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    final isSelected = selectedIndex == index;
    // Highlighted in teal
    final color = isSelected ? const Color(0xFF00BFA5) : Colors.white70;

    return InkWell(
      onTap: () => onItemSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00BFA5).withValues(alpha:0.1) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFF00BFA5) : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCard() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF29B6F6), Color(0xFF0288D1)], // Light blue gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0288D1).withValues(alpha:0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Khám phá thế giới cùng VietAI Travel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gợi ý điểm đến, lịch trình và trải nghiệm tuyệt vời dành riêng cho bạn.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0288D1),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Khám phá ngay',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
