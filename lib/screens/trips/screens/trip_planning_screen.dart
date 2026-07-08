import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/models/auth_session.dart';

import 'create_trip_screen.dart';
import 'trip_itinerary_history_screen.dart';
import 'trip_planning/trip_recent_section.dart';

/// Trang chính "Tạo chuyến đi" trong app. Đồng bộ style với
/// `CreateTripScreen` (cùng `_bg`, `_ink`, `_primary`) — tối ưu cho mobile,
/// có tỉ lệ rõ ràng trên desktop.
class TripPlanningScreen extends StatelessWidget {
  const TripPlanningScreen({super.key});

  // ─── Palette — đồng bộ với create_trip_screen / result screen ────────────────
  static const _bg = Color(0xFFF5F7F4);
  static const _ink = Color(0xFF15221D);
  static const _muted = Color(0xFF6E7A74);
  static const _primary = Color(0xFF008F6A);
  static const _primarySoft = Color(0xFFE6F6F0);

  void _goCreate(BuildContext ctx) => Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => const CreateTripScreen()),
      );

  void _goHistory(BuildContext ctx) => Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => const TripItineraryHistoryScreen()),
      );

  AuthUser? _currentUser(BuildContext context) {
    return VietaiScope.of(context).auth?.user;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Chúc bạn ngủ ngon';
    if (hour < 11) return 'Chào buổi sáng';
    if (hour < 14) return 'Chào buổi trưa';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser(context);
    final displayName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : (user?.username ?? 'bạn');

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context, user),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _HeroGreeting(
                    greeting: _greeting(),
                    name: displayName,
                    onCreate: () => _goCreate(context),
                    onHistory: () => _goHistory(context),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: 18),
                  const _StatsRow()
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 500.ms)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: 22),
                  const _SectionTitle('Khám phá nhanh'),
                  SizedBox(height: 12),
                  _QuickGrid(
                    onCreate: () => _goCreate(context),
                    onHistory: () => _goHistory(context),
                  )
                      .animate()
                      .fadeIn(delay: 160.ms, duration: 500.ms)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: 26),
                  _SectionTitle(
                    'Hành trình gần đây',
                    action: 'Xem tất cả',
                    onAction: () => _goHistory(context),
                  ),
                  const SizedBox(height: 12),
                  TripRecentSection(onCreate: () => _goCreate(context))
                      .animate()
                      .fadeIn(delay: 240.ms, duration: 500.ms)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: 24),
                  const _TravelTipsCard()
                      .animate()
                      .fadeIn(delay: 320.ms, duration: 500.ms)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, AuthUser? user) {
    final firstChar =
        ((user?.fullName.isNotEmpty == true ? user!.fullName : (user?.username ?? '?'))
                .trim()
                .characters
                .firstOrNull ?? 'T')
            .toUpperCase();
    return SliverAppBar(
      pinned: true,
      backgroundColor: _bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleSpacing: 18,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primary, Color(0xFF05B581)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              firstChar,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Travel byTemp',
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Lịch sử chuyến đi',
          onPressed: () => _goHistory(context),
          icon: const Icon(Icons.history_rounded, color: _ink),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─── Hero greeting with primary CTA ──────────────────────────────────────────
class _HeroGreeting extends StatelessWidget {
  const _HeroGreeting({
    required this.greeting,
    required this.name,
    required this.onCreate,
    required this.onHistory,
  });

  final String greeting;
  final String name;
  final VoidCallback onCreate;
  final VoidCallback onHistory;

  static const _primary = TripPlanningScreen._primary;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF008F6A), Color(0xFF05B581), Color(0xFF34D399)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF008F6A).withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 13, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'AI Travel Planner',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$greeting,',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sẵn sàng cho chuyến đi tiếp theo? Hãy để AI gợi ý lịch trình phù hợp với bạn.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        onTap: onCreate,
                        borderRadius: BorderRadius.circular(18),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_location_alt_rounded, size: 18, color: _primary),
                              SizedBox(width: 8),
                              Text(
                                'Tạo hành trình',
                                style: TextStyle(
                                  color: _primary,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: onHistory,
                      borderRadius: BorderRadius.circular(18),
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(Icons.history_rounded, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Decorative blob — top-right
        Positioned(
          right: -30,
          top: -30,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
        Positioned(
          right: 30,
          bottom: -20,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Stats row (2 cards) ─────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  static const _primary = TripPlanningScreen._primary;
  static const _primarySoft = TripPlanningScreen._primarySoft;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.auto_awesome_motion_rounded,
            iconColor: _primary,
            iconBg: _primarySoft,
            value: 'AI Planner',
            label: 'Hành trình thông minh',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.savings_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFFFEF3C7),
            value: '~12%',
            label: 'Tiết kiệm chi phí',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  static const _ink = TripPlanningScreen._ink;
  static const _muted = TripPlanningScreen._muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
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

// ─── Quick Action grid (4 items) ─────────────────────────────────────────────
class _QuickGrid extends StatelessWidget {
  const _QuickGrid({required this.onCreate, required this.onHistory});

  final VoidCallback onCreate;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickTile(
        icon: Icons.add_location_alt_rounded,
        title: 'Tạo hành trình',
        subtitle: 'AI lên lịch',
        color: const Color(0xFF008F6A),
        bg: const Color(0xFFE6F6F0),
        onTap: onCreate,
      ),
      _QuickTile(
        icon: Icons.history_rounded,
        title: 'Lịch sử',
        subtitle: 'Chuyến đã lưu',
        color: const Color(0xFF0D9488),
        bg: const Color(0xFFCCFBF1),
        onTap: onHistory,
      ),
      _QuickTile(
        icon: Icons.map_rounded,
        title: 'Bản đồ',
        subtitle: 'Xem tuyến đường',
        color: const Color(0xFFF97316),
        bg: const Color(0xFFFFEDD5),
        onTap: onCreate,
      ),
      _QuickTile(
        icon: Icons.tips_and_updates_rounded,
        title: 'Mẹo hay',
        subtitle: 'Từ cộng đồng',
        color: const Color(0xFF8B5CF6),
        bg: const Color(0xFFEDE9FE),
        onTap: onCreate,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.45,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: items,
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  static const _ink = TripPlanningScreen._ink;
  static const _muted = TripPlanningScreen._muted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8E4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section title ───────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  static const _ink = TripPlanningScreen._ink;
  static const _primary = TripPlanningScreen._primary;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: -0.1,
          ),
        ),
        const Spacer(),
        if (action != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      action!,
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: _primary),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Travel tips card ────────────────────────────────────────────────────────
class _TravelTipsCard extends StatelessWidget {
  const _TravelTipsCard();

  static const _ink = TripPlanningScreen._ink;
  static const _muted = TripPlanningScreen._muted;
  static const _primary = TripPlanningScreen._primary;
  static const _primarySoft = TripPlanningScreen._primarySoft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: _primarySoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF008F6A), Color(0xFF05B581)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.tips_and_updates_rounded, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Mẹo cho chuyến đi của bạn',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Đặt vé vào giữa tuần thường có giá rẻ hơn 15-25%. '
                  'AI sẽ gợi ý những điểm đến phù hợp với ngân sách và sở thích của bạn.',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
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
