import 'package:flutter/material.dart';
import 'package:assignment/core/theme/app_colors.dart';
import 'package:assignment/core/widgets/gradient_button.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/data/mock_data.dart';
import 'package:assignment/services/api_client.dart';
import 'package:assignment/services/app_session.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var _requestedSchedules = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = VietaiScope.of(context);
    if (!_requestedSchedules && session.isLoggedIn && session.schedules.isEmpty) {
      _requestedSchedules = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) VietaiScope.of(context).loadSchedules();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = VietaiScope.of(context);
    final user = session.auth?.user;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: session.loadSchedules,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(
                user?.fullName ?? MockData.userName,
                user?.email ?? MockData.userEmail,
                session,
              ),
            ),
            SliverToBoxAdapter(child: _buildStats(session)),
            SliverToBoxAdapter(child: _buildMyTrips(session)),
            SliverToBoxAdapter(child: _buildQuickAccess()),
            SliverToBoxAdapter(child: _buildSettings()),
            SliverToBoxAdapter(child: _buildRewardsBanner()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
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
          child: const Opacity(
            opacity: 0.15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
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
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.primary,
                        ),
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
                          child: const Icon(
                            Icons.edit,
                            size: 12,
                            color: Colors.white,
                          ),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.landscape,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                session.auth?.user.role ?? 'Traveler',
                                style: const TextStyle(
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
                onPressed: session.logout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Logout'),
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

  Widget _buildStats(AppSession session) {
    final stats = [
      (Icons.luggage, AppColors.primary, '${session.schedules.length}', 'AI Trips'),
      (Icons.favorite, Colors.red, '48', 'Saved Places'),
      (Icons.star, Colors.amber, '126', 'Reviews'),
      (
        Icons.account_balance_wallet,
        AppColors.accentPurple,
        _totalBudgetText(session.schedules),
        'Budget',
      ),
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
                  Text(
                    s.$3,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.$4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMyTrips(AppSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Trips',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: session.loadSchedules,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
        if (session.schedulesLoading)
          const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (session.schedulesError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _TripsMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Cannot load trips',
              subtitle: 'Start the backend API, then try again.',
              actionLabel: 'Try again',
              onPressed: session.loadSchedules,
            ),
          )
        else if (session.schedules.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _TripsMessage(
              icon: Icons.event_note_outlined,
              title: 'No AI trips yet',
              subtitle: 'Generate an itinerary and it will appear here.',
              actionLabel: 'Reload',
              onPressed: session.loadSchedules,
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: session.schedules.length,
              itemBuilder: (_, i) {
                final trip = session.schedules[i];
                return Container(
                  width: 260,
                  margin: EdgeInsets.only(
                    right: i < session.schedules.length - 1 ? 12 : 0,
                  ),
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
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.4),
                                  AppColors.primaryDark.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.route_outlined,
                                color: Colors.white,
                                size: 42,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${trip.totalDays} days',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
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
                                  Text(
                                    trip.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    trip.userLocationName ?? 'AI itinerary',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${_budgetText(trip.budgetInput)} - ${_dateText(trip.generatedAt)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textHint,
                            ),
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
      (Icons.confirmation_number, AppColors.primary, 'Bookings'),
      (Icons.favorite, Colors.red, 'Saved Places'),
      (Icons.account_balance_wallet, AppColors.accentBlue, 'Budgets'),
      (Icons.credit_card, AppColors.accentPurple, 'Payments'),
      (Icons.person_add, Colors.orange, 'Invite'),
      (Icons.diamond, AppColors.primary, 'Points'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Access',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
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
                  Text(
                    item.$3,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
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
      ('Privacy & Security', 'Password and account data'),
      ('Help & Support', 'FAQ and contact'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Container(
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
                        Text(
                          item.$1,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textHint),
                ],
              ),
            ),
          ),
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
                  Text(
                    "You're doing great!",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Keep exploring and earn more points.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 110,
              child: GradientButton(
                label: 'Explore',
                compact: true,
                height: 40,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Use the Explore tab below to keep exploring')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _totalBudgetText(List<ScheduleSummary> schedules) {
    final total = schedules.fold<double>(0, (sum, item) => sum + item.budgetInput);
    if (total <= 0) return '0';
    if (total >= 1000000) return '${(total / 1000000).toStringAsFixed(1)}M';
    return total.toStringAsFixed(0);
  }

  String _budgetText(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M VND';
    return '${value.toStringAsFixed(0)} VND';
  }

  String _dateText(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _TripsMessage extends StatelessWidget {
  const _TripsMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
