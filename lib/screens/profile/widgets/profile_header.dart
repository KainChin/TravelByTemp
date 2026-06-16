import 'dart:ui';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final VoidCallback onEditTap;

  const ProfileHeader({super.key, required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/banner_bac.png'), // Hình nền cao cấp từ local
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Lớp phủ Gradient tối giúp làm nổi bật chữ (Premium feel)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
          // Nút thao tác góc trên phải (Glassmorphism)
          Positioned(
            top: 52, right: 16,
            child: Row(
              children: [
                _actionBtn(Icons.ios_share_outlined),
                const SizedBox(width: 12),
                _actionBtn(Icons.settings_outlined),
              ],
            ),
          ),
          // Thông tin người dùng góc dưới trái
          Positioned(
            bottom: 24, left: 20, right: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(),
                const SizedBox(width: 16),
                Expanded(child: _buildUserInfo()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
          ),
          child: Icon(icon, size: 22, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF3A7D5A), Color(0xFF81C784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ]
      ),
      child: Stack(
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF3A7D5A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text('Thu Duc', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onEditTap,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text('"Collect moments, not things."', style: TextStyle(fontSize: 14, color: Colors.white70, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF3A7D5A).withOpacity(0.8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.location_on, size: 12, color: Colors.white),
            ),
            const SizedBox(width: 6),
            const Text('Hanoi, Vietnam', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
