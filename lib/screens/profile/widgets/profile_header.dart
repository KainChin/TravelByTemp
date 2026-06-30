import 'dart:ui';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final VoidCallback onEditTap;
  final String fullName;
  final String username;
  final String email;
  final String? bio;
  final String role;
  final String location;
  final VoidCallback onLogoutTap;

  const ProfileHeader({
    super.key,
    required this.onEditTap,
    required this.onLogoutTap,
    required this.fullName,
    required this.username,
    required this.email,
    this.bio,
    required this.role,
    required this.location,
  });

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
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.8),
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
                _actionBtn(Icons.logout_outlined, onTap: onLogoutTap),
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

  Widget _actionBtn(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initial = fullName.trim().isEmpty
        ? username.trim().isEmpty
            ? 'T'
            : username.trim()[0].toUpperCase()
        : fullName.trim()[0].toUpperCase();

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
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ]
      ),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: const Color(0xFF3A7D5A),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
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
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))
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
    final displayName = fullName.trim().isEmpty ? username : fullName.trim();
    final subtitle = (bio ?? '').trim().isNotEmpty
        ? (bio ?? '').trim()
        : (email.trim().isEmpty ? '@$username' : email.trim());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onEditTap,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF3A7D5A).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.location_on, size: 12, color: Colors.white),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$location • $role',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

