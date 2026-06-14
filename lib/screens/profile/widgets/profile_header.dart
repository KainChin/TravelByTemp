import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final VoidCallback onEditTap;

  const ProfileHeader({super.key, required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB8D8E8), Color(0xFFD4E8D4), Color(0xFFA8C8B8)],
        ),
      ),
      child: Stack(
        children: [
          // Action buttons (top-right)
          Positioned(
            top: 52, right: 16,
            child: Row(
              children: [
                _actionBtn(Icons.ios_share_outlined),
                const SizedBox(width: 8),
                _actionBtn(Icons.settings_outlined),
              ],
            ),
          ),
          // Avatar + Info (bottom-left)
          Positioned(
            bottom: 16, left: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildAvatar(),
                const SizedBox(width: 14),
                _buildUserInfo(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 20, color: Colors.black87),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        const CircleAvatar(
          radius: 36,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
        ),
        Positioned(
          bottom: 0, right: 0,
          child: Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF3A7D5A),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text('Thu Duc', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onEditTap,
              child: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF3A7D5A)),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text('"Collect moments, not things."', style: TextStyle(fontSize: 12, color: Color(0xFF444444))),
        const SizedBox(height: 2),
        const Row(
          children: [
            Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF555555)),
            SizedBox(width: 2),
            Text('Hanoi, Vietnam', style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
          ],
        ),
      ],
    );
  }
}