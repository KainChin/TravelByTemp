// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

class TimelineSection extends StatelessWidget {
  const TimelineSection({
    super.key,
    required this.day,
    required this.onAdd,
    required this.onEdit,
    required this.onOptimize,
    required this.onDelete,
  });

  final Object? day;
  final VoidCallback onAdd;
  final void Function(Map<String, dynamic> activity, int index) onEdit;
  final void Function(Map<String, dynamic> activity, int index) onOptimize;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    final activities = _activitiesFor(day);
    return _Surface(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lịch trình trong ngày',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Thêm', style: TextStyle(fontWeight: FontWeight.w800)),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (activities.isEmpty)
            const _EmptyState()
          else
            ...activities.asMap().entries.map((entry) {
              final index = entry.key;
              final item = Map<String, dynamic>.from(entry.value);
              final next = index + 1 < activities.length
                  ? Map<String, dynamic>.from(activities[index + 1])
                  : null;
              return ActivityTimelineCard(
                activity: item,
                nextActivity: next,
                index: index,
                isLast: index == activities.length - 1,
                onEdit: () => onEdit(item, index),
                onOptimize: () => onOptimize(item, index),
                onDelete: () => onDelete(index),
              ).animate(delay: (200 + index * 100).ms).fadeIn(duration: 500.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutBack);
            }),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}

class ActivityTimelineCard extends StatelessWidget {
  const ActivityTimelineCard({
    super.key,
    required this.activity,
    required this.nextActivity,
    required this.index,
    required this.isLast,
    required this.onEdit,
    required this.onOptimize,
    required this.onDelete,
  });

  final Map<String, dynamic> activity;
  final Map<String, dynamic>? nextActivity;
  final int index;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onOptimize;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = _activityTitle(activity);
    final destination = '${activity['destination'] ?? ''}'.trim();
    final address = '${activity['address'] ?? ''}'.trim();
    final note = '${activity['note'] ?? activity['transport'] ?? ''}'.trim();
    final time = '${activity['time'] ?? ''}'.trim();
    final duration = _activityDuration(activity);
    final category = _activityCategory(activity);
    final rating = _activityRating(activity);
    final nextDistance = _distanceToNextLabel(activity, nextActivity);
    final hasPlace = destination.isNotEmpty || address.isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line and dot
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF4338CA), width: 2),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF4338CA).withValues(alpha: 0.2), blurRadius: 8),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF4338CA),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 4, bottom: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF4338CA), Color(0xFF0EA5E9)],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [BoxShadow(color: Color(0x080F172A), blurRadius: 20, offset: Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _ActivityMeta(icon: Icons.schedule_outlined, label: time.isEmpty ? '--:--' : time, color: const Color(0xFF0EA5E9)),
                                _ActivityMeta(icon: Icons.payments_outlined, label: _formatMoney(_activityCost(activity)), color: const Color(0xFFF59E0B)),
                                _ActivityMeta(icon: Icons.category_outlined, label: category, color: const Color(0xFF8B5CF6)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              title,
                              style: const TextStyle(
                                color: _TripItineraryResultScreenState._ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ActivityMenu(
                        onEdit: onEdit,
                        onOptimize: onOptimize,
                        onDelete: onDelete,
                      ),
                    ],
                  ),
                  if (destination.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      destination,
                      style: const TextStyle(
                        color: Color(0xFF4338CA), // Accent color
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _TripItineraryResultScreenState._muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (duration.isNotEmpty || nextDistance.isNotEmpty || rating.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        if (duration.isNotEmpty) _ActivityMeta(icon: Icons.timelapse_outlined, label: duration, color: _TripItineraryResultScreenState._muted),
                        if (nextDistance.isNotEmpty) _ActivityMeta(icon: Icons.near_me_outlined, label: nextDistance, color: _TripItineraryResultScreenState._muted),
                        if (rating.isNotEmpty) _ActivityMeta(icon: Icons.star_rate_rounded, label: rating, color: const Color(0xFFF59E0B)),
                      ],
                    ),
                  ],
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF4338CA)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              note,
                              style: const TextStyle(
                                color: _TripItineraryResultScreenState._muted,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (hasPlace) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _PlaceAction(label: 'Mở Google Maps', icon: Icons.map_outlined, onTap: () => _openMaps(activity)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityMenu extends StatelessWidget {
  const _ActivityMenu({
    required this.onEdit,
    required this.onOptimize,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onOptimize;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit' || value == 'time' || value == 'place') onEdit();
        if (value == 'ai') onOptimize();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
        PopupMenuItem(value: 'time', child: Text('Đổi giờ')),
        PopupMenuItem(value: 'place', child: Text('Đổi địa điểm')),
        PopupMenuItem(value: 'ai', child: Text('AI tối ưu lại hoạt động này')),
        PopupMenuItem(value: 'delete', child: Text('Xóa')),
      ],
    );
  }
}

class _ActivityMeta extends StatelessWidget {
  const _ActivityMeta({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PlaceAction extends StatelessWidget {
  const _PlaceAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF4338CA),
        side: BorderSide(color: const Color(0xFF4338CA).withValues(alpha: 0.2)),
        backgroundColor: const Color(0xFF4338CA).withValues(alpha: 0.05),
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
