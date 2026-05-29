import 'package:flutter/material.dart';
import 'package:assignment/core/theme/app_colors.dart';
import 'package:assignment/core/widgets/gradient_button.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/data/mock_data.dart';
import 'package:assignment/services/app_session.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = VietaiScope.of(context);
    final user = session.auth?.user;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(user?.fullName ?? MockData.userName, user?.email ?? MockData.userEmail, session)),
          SliverToBoxAdapter(child: _buildStats()),
          SliverToBoxAdapter(child: _buildMyTrips()),
          SliverToBoxAdapter(child: _buildQuickAccess()),
          SliverToBoxAdapter(child: _buildSettings()),
          SliverToBoxAdapter(child: _buildRewardsBanner()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, String email, AppSession session) {
    return Stack(
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryLight.withValues(alpha: 0.6),
                AppColors.background,
              ],
            ),
          ),
          child: Opacity(
            opacity: 0.15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Icon(Icons.landscape, size: 60),
                Icon(Icons.park, size: 50),
                Icon(Icons.airplanemode_active, size: 40),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _iconBtn(Icons.settings_outlined),
                  const SizedBox(width: 8),
                  Stack(
                    children: [
                      _iconBtn(Icons.notifications_outlined),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(Icons.person, size: 40, color: AppColors.primary),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.landscape, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                session.auth?.user.role ?? 'Traveler',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => session.logout(),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Đăng xuất'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Icon(icon, size: 20),
    );
  }

  Widget _buildStats() {
    final stats = [
      (Icons.luggage, AppColors.primary, '12', 'Trips Completed'),
      (Icons.favorite, Colors.red, '48', 'Saved Places'),
      (Icons.star, Colors.amber, '126', 'Reviews Shared'),
      (Icons.account_balance_wallet, AppColors.accentPurple, '15.2M', 'Travel Points'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(s.$1, color: s.$2, size: 22),
                  const SizedBox(height: 8),
                  Text(s.$3, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(
                    s.$4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMyTrips() {
    final trips = <(String, String, Color, String, String)>[
      ('Đà Lạt & Nha Trang', 'Upcoming', Colors.green, '3 Days • 2 Places', 'May 20 – May 22, 2024'),
      ('Phú Quốc', 'Completed', AppColors.primary, '4 Days • 1 Place', 'Apr 1 – Apr 4, 2024'),
      ('Sa Pa', 'Draft', Colors.orange, '2 Days • 1 Place', 'Draft'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Trips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text('View All >', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: trips.length,
            itemBuilder: (_, i) {
              final t = trips[i];
              return Container(
                width: 260,
                margin: EdgeInsets.only(right: i < trips.length - 1 ? 12 : 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 110,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.4),
                                AppColors.primaryDark.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: t.$3.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              t.$2,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(t.$4, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                if (t.$5 != 'Draft')
                                  Text(t.$5, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.textHint),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccess() {
    final items = [
      (Icons.confirmation_number, AppColors.primary, 'My Bookings'),
      (Icons.favorite, Colors.red, 'Saved Places'),
      (Icons.account_balance_wallet, AppColors.accentBlue, 'Travel Budgets'),
      (Icons.credit_card, AppColors.accentPurple, 'Payment Methods'),
      (Icons.person_add, Colors.orange, 'Invite Friends'),
      (Icons.diamond, AppColors.primary, 'Travel Points'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 8,
            childAspectRatio: 0.9,
            children: items.map((item) {
              return Column(
                children: [
                  Icon(item.$1, color: item.$2, size: 28),
                  const SizedBox(height: 8),
                  Text(item.$3, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    final items = [
      ('Personal Information', 'Update your profile details'),
      ('Preferences', 'Language, currency, theme'),
      ('Notifications', 'Manage alerts and reminders'),
      ('Privacy & Security', 'Password, 2FA, data'),
      ('Help & Support', 'FAQ, contact us'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings & Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.settings, color: AppColors.primary, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(item.$2, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textHint),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRewardsBanner() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.card_giftcard, size: 48, color: AppColors.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("You're doing great!", style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text(
                    'Keep exploring and earn more points to unlock exclusive rewards.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 110,
              child: GradientButton(
                label: 'Explore Rewards',
                compact: true,
                height: 40,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
