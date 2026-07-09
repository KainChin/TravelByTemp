import 'dart:ui';
import 'package:assignment/core/widgets/safe_network_image.dart';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.onEditTap,
    required this.onShareTap,
    required this.onAvatarTap,
    required this.onLogoutTap,
    required this.fullName,
    required this.username,
    required this.email,
    this.bio,
    required this.role,
    required this.location,
    this.avatarUrl,
    this.onMenuTap,
  });

  final VoidCallback? onMenuTap;
  final VoidCallback onEditTap;
  final VoidCallback onShareTap;
  final VoidCallback onAvatarTap;
  final VoidCallback onLogoutTap;
  final String fullName;
  final String username;
  final String email;
  final String? bio;
  final String role;
  final String location;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // ── Background image ──
          Positioned.fill(
            child: Image.asset(
              'assets/images/chatAI.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          // ── Dark gradient overlay ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.35, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.52),
                    Colors.black.withValues(alpha: 0.90),
                  ],
                ),
              ),
            ),
          ),
          // ── Content ──
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // Hamburger Menu (only visible on mobile/if provided)
                      if (onMenuTap != null) ...[
                        _GlassIconButton(
                          icon: Icons.menu,
                          onTap: onMenuTap!,
                        ),
                        const SizedBox(width: 12),
                      ],
                      // VietAI Travel logo
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A7D5A),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.travel_explore, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'VietAI Travel',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ]),
                      const Spacer(),
                      // Share icon
                      _GlassIconButton(
                        icon: Icons.ios_share_outlined,
                        onTap: onShareTap,
                      ),
                      const SizedBox(width: 10),
                      // Logout icon
                      _GlassIconButton(
                        icon: Icons.logout_outlined,
                        onTap: onLogoutTap,
                      ),
                    ],
                  ),
                ),
                // Spacing
                const SizedBox(height: 20),
                // User info section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar + name/username/location row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _Avatar(
                            fullName: fullName,
                            username: username,
                            avatarUrl: avatarUrl,
                            onTap: onAvatarTap,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Name + verified badge
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        fullName.trim().isEmpty ? username : fullName.trim(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 19,
                                      height: 19,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF3A7D5A),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, color: Colors.white, size: 12),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: onEditTap,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.edit_outlined, color: Colors.white, size: 11),
                                            SizedBox(width: 4),
                                            Text(
                                              'Sửa',
                                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // @username
                                Text(
                                  '@$username',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white60,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Location
                                Row(children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.white60),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      location.trim().isEmpty ? role : location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, color: Colors.white60),
                                    ),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Bio quote
                      if ((bio ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 11),
                        Text(
                          '"${bio!.trim()}"',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.fullName,
    required this.username,
    required this.avatarUrl,
    required this.onTap,
  });

  final String fullName;
  final String username;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = fullName.trim().isEmpty
        ? (username.trim().isEmpty ? 'T' : username.trim()[0].toUpperCase())
        : fullName.trim()[0].toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF3A7D5A), Color(0xFF81C784)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0x22000000),
          ),
          child: ClipOval(
            child: SizedBox(
              width: 80,
              height: 80,
              child: avatarUrl?.trim().isNotEmpty == true
                  ? SafeNetworkImage(
                      url: avatarUrl!.trim(),
                      source: 'profile avatar',
                      fallback: _InitialAvatar(initial: initial),
                    )
                  : _InitialAvatar(initial: initial),
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 40,
      backgroundColor: const Color(0xFF3A7D5A),
      child: Text(
        initial,
        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
      ),
    );
  }
}
