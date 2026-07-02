// ignore_for_file: use_string_in_part_of_directives
part of saved_screen;

class _DashboardMetric extends StatefulWidget {
  const _DashboardMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  State<_DashboardMetric> createState() => _DashboardMetricState();
}

class _DashboardMetricState extends State<_DashboardMetric> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(minHeight: 104),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? widget.color.withValues(alpha: 0.28)
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.055 : 0.025),
              blurRadius: _hovered ? 18 : 10,
              offset: Offset(0, _hovered ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(widget.icon, size: 18, color: widget.color),
            ),
            const SizedBox(height: 12),
            Text(
              widget.value,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedDashboardPanel extends StatelessWidget {
  const _SavedDashboardPanel({
    required this.trips,
    required this.places,
  });

  final int trips;
  final int places;

  @override
  Widget build(BuildContext context) {
    return _SavedSidePanel(
      title: 'Quick Statistics',
      icon: Icons.dashboard_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DashboardMetric(
                  icon: Icons.map_rounded,
                  value: '$trips',
                  label: 'Trips',
                  color: const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DashboardMetric(
                  icon: Icons.favorite_rounded,
                  value: '$places',
                  label: 'Places',
                  color: const Color(0xFFE11D48),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: _DashboardMetric(
                  icon: Icons.savings_rounded,
                  value: '15%',
                  label: 'Savings',
                  color: Color(0xFFF97316),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _DashboardMetric(
                  icon: Icons.star_rounded,
                  value: '4.8',
                  label: 'Rating',
                  color: Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavedInsightPanel extends StatelessWidget {
  const _SavedInsightPanel();

  @override
  Widget build(BuildContext context) {
    return const _SavedSidePanel(
      title: 'Travel Tips',
      icon: Icons.tips_and_updates_rounded,
      child: Column(
        children: [
          _SavedInsightRow(
            icon: Icons.wb_sunny_rounded,
            title: 'Weather',
            subtitle: 'Da Lat and Phu Quoc are in a strong travel window.',
            color: Color(0xFFF59E0B),
          ),
          SizedBox(height: 10),
          _SavedInsightRow(
            icon: Icons.local_fire_department_rounded,
            title: 'Trending',
            subtitle: 'Beach trips and 3-day routes are getting more saves.',
            color: Color(0xFFF97316),
          ),
          SizedBox(height: 10),
          _SavedInsightRow(
            icon: Icons.update_rounded,
            title: 'Recent Activity',
            subtitle: 'AI recalculated budgets from your saved trips.',
            color: Color(0xFF0D9488),
          ),
        ],
      ),
    );
  }
}

class _SavedInsightRow extends StatelessWidget {
  const _SavedInsightRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SavedSidePanel extends StatelessWidget {
  const _SavedSidePanel({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF16A34A)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
