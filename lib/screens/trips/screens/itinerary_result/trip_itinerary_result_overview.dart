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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            const Color(0xFF00A879),
            const Color(0xFF0B7D4B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                SizedBox(width: 7),
                Text(
                  'VietAI Travel Planner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.38,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _HeroMetric(icon: Icons.calendar_today_outlined, label: '$daysCount ngày'),
              _HeroMetric(icon: Icons.place_outlined, label: '$destinationCount địa điểm'),
              _HeroMetric(icon: Icons.explore_outlined, label: '$activitiesCount hoạt động'),
              _HeroMetric(
                icon: Icons.payments_outlined,
                label: _moneyOrStatus(totalCost, empty: 'Đang tính...'),
              ),
              _HeroMetric(
                icon: Icons.star_rate_rounded,
                label: 'AI Score ${aiScore.toStringAsFixed(1)}/10',
              ),
              _HeroMetric(icon: Icons.task_alt_outlined, label: status),
            ],
          ),
        ],
      ),
    );
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _QuickActionButton(
            icon: Icons.navigation_outlined,
            label: 'Điều hướng',
            onPressed: onNavigate,
          ),
          _QuickActionButton(
            icon: Icons.edit_outlined,
            label: 'Chỉnh sửa',
            onPressed: onEdit,
          ),
          _QuickActionButton(
            icon: Icons.auto_awesome_outlined,
            label: 'AI tối ưu',
            onPressed: onOptimize,
          ),
          _QuickActionButton(
            icon: Icons.ios_share_outlined,
            label: 'Chia sẻ',
            onPressed: onShare,
          ),
          _QuickActionButton(
            icon: Icons.bookmark_add_outlined,
            label: 'Lưu',
            onPressed: onSave,
          ),
        ],
      ),
    );
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
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          final day = days[index];
          final dayCost = _dayCost(day);
          final dayHours = _dayDurationHours(day);
          final foreground = selected ? Colors.white : _TripItineraryResultScreenState._ink;
          return Material(
            color: selected ? scheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onChanged(index),
              child: Container(
                width: 146,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? scheme.primary : _TripItineraryResultScreenState._line,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ngày ${day['day'] ?? index + 1}',
                      style: TextStyle(color: foreground, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_activitiesFor(day).length} hoạt động',
                      style: TextStyle(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.82)
                            : _TripItineraryResultScreenState._muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _moneyOrStatus(dayCost, empty: 'Đang tính...'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _formatHoursCompact(dayHours),
                      style: TextStyle(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.86)
                            : _TripItineraryResultScreenState._muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
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
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
    );
  }
}
