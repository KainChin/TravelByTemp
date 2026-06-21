import 'package:flutter/material.dart';

class ExploreHeader extends StatelessWidget {
  // TODO: Replace with UserModel from API: GET /api/users/me
  final String userName;
  final String? avatarUrl;
  final VoidCallback? onNotificationTap;

  const ExploreHeader({
    super.key,
    this.userName = 'Thu Duc',
    this.avatarUrl,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(url: avatarUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Xin chào 👋',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
        _NotificationButton(onTap: onNotificationTap),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  const _Avatar({this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF16A34A), width: 2),
      ),
      child: ClipOval(
        child: url != null
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _DefaultAvatar(),
              )
            : const _DefaultAvatar(),
      ),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFE5E7EB),
        child: const Icon(Icons.person, color: Color(0xFF9CA3AF), size: 28),
      );
}

class _NotificationButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _NotificationButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_outlined, size: 22, color: Color(0xFF374151)),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
