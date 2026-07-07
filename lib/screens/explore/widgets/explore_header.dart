import 'package:flutter/material.dart';
import 'package:assignment/core/widgets/safe_network_image.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';

class ExploreHeader extends StatelessWidget {
  const ExploreHeader({
    super.key,
    this.userName = 'Khách',
    this.avatarUrl,
    this.onNotificationTap,
    this.onProfileTap,
    this.onSettingsTap,
    this.onLogoutTap,
  });

  final String userName;
  final String? avatarUrl;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final session = VietaiScope.of(context);
    final user = session.auth?.user;
    final displayUserName = user?.fullName ?? userName;
    final resolvedAvatarUrl = avatarUrl ?? user?.avatarUrl;
    final locationName = session.locationName;

    return Row(
      children: [
        _Avatar(
          url: resolvedAvatarUrl,
          name: displayUserName,
          onTap: () => _showAccountSheet(context),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào, $displayUserName',
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
        _NotificationButton(onTap: onNotificationTap ?? () => _showAccountSheet(context)),
      ],
    );
  }

  void _showAccountSheet(BuildContext context) {
    final session = VietaiScope.of(context);
    final user = session.auth?.user;
    final displayName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : user?.username ?? userName;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Avatar(url: user?.avatarUrl, name: displayName),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user == null ? 'Chưa đăng nhập' : 'Đang hoạt động - ${user.role}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _AccountAction(
                  icon: Icons.person_outline,
                  title: 'Xem hồ sơ',
                  subtitle: 'Mở trang Profile và trạng thái tài khoản',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onProfileTap?.call();
                  },
                ),
                _AccountAction(
                  icon: Icons.settings_outlined,
                  title: 'Cài đặt hồ sơ',
                  subtitle: 'Sửa tên, email, bio, avatar',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onSettingsTap?.call();
                  },
                ),
                _AccountAction(
                  icon: Icons.logout_rounded,
                  title: 'Đăng xuất',
                  subtitle: 'Thoát khỏi tài khoản hiện tại',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onLogoutTap?.call();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url, this.name, this.onTap});

  final String? url;
  final String? name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF1976D2), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: url?.trim().isNotEmpty == true
                ? SafeNetworkImage(
                    url: url!.trim(),
                    fit: BoxFit.cover,
                    fallback: _DefaultAvatar(name: name),
                    source: 'explore avatar',
                  )
                : _DefaultAvatar(name: name),
          ),
        ),
      ),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name?.trim() ?? '';
    final initial = trimmed.isEmpty ? null : trimmed[0].toUpperCase();
    return Container(
      color: const Color(0xFFE8F5EF),
      alignment: Alignment.center,
      child: initial == null
          ? const Icon(Icons.person, color: Color(0xFF1976D2), size: 28)
          : Text(
              initial,
              style: const TextStyle(
                color: Color(0xFF1976D2),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _AccountAction extends StatelessWidget {
  const _AccountAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFDC2626) : const Color(0xFF111827);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: destructive ? const Color(0xFFFEE2E2) : const Color(0xFFE8F5EF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: destructive ? color : const Color(0xFF1976D2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: color, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({this.onTap});

  final VoidCallback? onTap;

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
                  color: Color(0xFF1976D2),
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
