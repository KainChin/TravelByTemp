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
      padding: const EdgeInsets.all(18),
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
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm'),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                onEdit: () => onEdit(item, index),
                onOptimize: () => onOptimize(item, index),
                onDelete: () => onDelete(index),
              );
            }),
        ],
      ),
    );
  }
}

class ActivityTimelineCard extends StatelessWidget {
  const ActivityTimelineCard({
    super.key,
    required this.activity,
    required this.nextActivity,
    required this.index,
    required this.onEdit,
    required this.onOptimize,
    required this.onDelete,
  });

  final Map<String, dynamic> activity;
  final Map<String, dynamic>? nextActivity;
  final int index;
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFFFDFEFD),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _TripItineraryResultScreenState._line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _TripItineraryResultScreenState._primarySoft,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: _TripItineraryResultScreenState._primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _ActivityMeta(icon: Icons.schedule_outlined, label: time.isEmpty ? '--:--' : time),
                              _ActivityMeta(icon: Icons.payments_outlined, label: _formatMoney(_activityCost(activity))),
                              _ActivityMeta(icon: Icons.category_outlined, label: category),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            style: const TextStyle(
                              color: _TripItineraryResultScreenState._ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
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
                      color: _TripItineraryResultScreenState._muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (address.isNotEmpty)
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _TripItineraryResultScreenState._muted,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    if (duration.isNotEmpty) _ActivityMeta(icon: Icons.timelapse_outlined, label: duration),
                    if (nextDistance.isNotEmpty) _ActivityMeta(icon: Icons.near_me_outlined, label: nextDistance),
                    if (rating.isNotEmpty) _ActivityMeta(icon: Icons.star_rate_rounded, label: rating),
                  ],
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Text(
                    note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _TripItineraryResultScreenState._muted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
                if (hasPlace) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _PlaceAction(label: 'Maps', icon: Icons.map_outlined, onTap: () => _openMaps(activity)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
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
  const _ActivityMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _TripItineraryResultScreenState._primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
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
      icon: Icon(icon, size: 13),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _TripItineraryResultScreenState._primary,
        side: const BorderSide(color: _TripItineraryResultScreenState._line),
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
