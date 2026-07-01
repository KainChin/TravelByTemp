// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

class TripHeroHeader extends StatelessWidget {
  const TripHeroHeader({
    super.key,
    required this.title,
    required this.summary,
    required this.daysCount,
    required this.destinationCount,
    required this.activitiesCount,
    required this.totalCost,
    required this.aiScore,
    required this.status,
  });

  final String title;
  final String summary;
  final int daysCount;
  final int destinationCount;
  final int activitiesCount;
  final num totalCost;
  final double aiScore;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF312E81), // Deep Indigo
            Color(0xFF4338CA), // Indigo
            Color(0xFF0284C7), // Light Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: 20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'VietAI Travel Planner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroMetric(icon: Icons.calendar_today_outlined, label: '$daysCount ngày'),
                    _HeroMetric(icon: Icons.place_outlined, label: '$destinationCount điểm đến'),
                    _HeroMetric(icon: Icons.explore_outlined, label: '$activitiesCount hoạt động'),
                    _HeroMetric(icon: Icons.payments_outlined, label: _moneyOrStatus(totalCost, empty: 'Đang tính...')),
                    _HeroMetric(icon: Icons.star_rate_rounded, label: 'AI Score ${aiScore.toStringAsFixed(1)}'),
                    _HeroMetric(icon: Icons.task_alt_outlined, label: status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0, curve: Curves.easeOutBack);
  }
}

class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.onNavigate,
    required this.onEdit,
    required this.onOptimize,
    required this.onShare,
    required this.onSave,
  });

  final VoidCallback onNavigate;
  final VoidCallback onEdit;
  final VoidCallback onOptimize;
  final VoidCallback onShare;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 32, offset: Offset(0, 12))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _QuickActionButton(icon: Icons.near_me_outlined, label: 'Điều hướng', color: const Color(0xFF0EA5E9), onTap: onNavigate),
          _QuickActionButton(icon: Icons.edit_outlined, label: 'Chỉnh sửa', color: const Color(0xFFF59E0B), onTap: onEdit),
          _QuickActionButton(icon: Icons.auto_awesome_outlined, label: 'AI tối ưu', color: const Color(0xFF8B5CF6), onTap: onOptimize),
          _QuickActionButton(icon: Icons.ios_share_outlined, label: 'Chia sẻ', color: const Color(0xFF10B981), onTap: onShare),
          _QuickActionButton(icon: Icons.bookmark_outline_rounded, label: 'Lưu', color: const Color(0xFFF43F5E), onTap: onSave),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}

class DaySelector extends StatelessWidget {
  const DaySelector({
    super.key,
    required this.days,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> days;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          final day = days[index];
          final dayCost = _dayCost(day);
          
          return GestureDetector(
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 140,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF4338CA) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected ? const Color(0xFF4338CA) : _TripItineraryResultScreenState._line.withValues(alpha: 0.5),
                ),
                boxShadow: selected
                    ? [BoxShadow(color: const Color(0xFF4338CA).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]
                    : const [BoxShadow(color: Color(0x030F172A), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ngày ${day['day'] ?? index + 1}',
                    style: TextStyle(
                      color: selected ? Colors.white : _TripItineraryResultScreenState._ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_activitiesFor(day).length} hoạt động',
                    style: TextStyle(
                      color: selected ? Colors.white.withValues(alpha: 0.8) : _TripItineraryResultScreenState._muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _moneyOrStatus(dayCost, empty: '--'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : _TripItineraryResultScreenState._ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: (300 + index * 100).ms).fadeIn(duration: 400.ms).scaleXY(begin: 0.8, end: 1, curve: Curves.easeOutBack);
        },
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(color: _TripItineraryResultScreenState._ink, fontSize: 11, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
