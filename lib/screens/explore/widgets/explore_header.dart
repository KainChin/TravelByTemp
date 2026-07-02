import 'package:flutter/material.dart';
import 'package:assignment/core/widgets/safe_network_image.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';

class ExploreHeader extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  final VoidCallback? onNotificationTap;

  const ExploreHeader({
    super.key,
    this.userName = 'Khách',
    this.avatarUrl,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final session = VietaiScope.of(context);
    final displayUserName = session.auth?.user.fullName ?? userName;
    final locationName = session.locationName;
    
    return Row(
      children: [
        _Avatar(url: avatarUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayUserName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      locationName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF6B7280)),
                ],
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
            ? SafeNetworkImage(
                url: url,
                fit: BoxFit.cover,
                fallback: const _DefaultAvatar(),
                source: 'explore avatar',
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
              color: Colors.black.withValues(alpha: 0.08),
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
