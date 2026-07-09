// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

class TimelineSection extends StatelessWidget {
  const TimelineSection({
    super.key,
    required this.day,
    required this.dayIndex,
    required this.totalDays,
    required this.onAdd,
    required this.onEdit,
    required this.onOptimize,
    required this.onDelete,
    this.onDayChanged,
    this.days = const [],
  });

  /// Map ngày thô từ state — dùng để suy ra destination đầu ngày cho header.
  final Object? day;
  final int dayIndex;
  final int totalDays;
  final VoidCallback onAdd;
  final void Function(Map<String, dynamic> activity, int index) onEdit;
  final void Function(Map<String, dynamic> activity, int index) onOptimize;
  final ValueChanged<int> onDelete;

  /// Callback khi user bấm chuyển ngày trong tab inline.
  final ValueChanged<int>? onDayChanged;

  /// Danh sách days đầy đủ để hiển thị nhãn cho từng tab ngày.
  final List<Map<String, dynamic>> days;

  /// Tên ngày hiển thị trong header. Luôn lấy trực tiếp từ `day` đã được
  /// _TripItineraryResultScreenState truyền vào (1-to-1 với _days[index]),
  /// tránh đọc nhầm dữ liệu ngày khác nếu state bị lệch.
  String _daySubtitle() {
    if (day is! Map) return 'Ngày ${dayIndex + 1}';
    final activities = _activitiesFor(day);
    String? firstDestination;
    if (activities.isNotEmpty) {
      // Ưu tiên activity thật, không phải placeholder do _expandActivities
      // tự fill (loại bỏ dòng có note 'Bấm "Thêm"...' để tránh hiển thị
      // 'Điểm đến ngày X' làm tiêu đề ngày).
      final realActivity = activities.firstWhere(
        (a) {
          final note = '${a['note'] ?? ''}';
          return !note.contains('Bấm "Thêm"');
        },
        orElse: () => activities.first,
      );
      firstDestination =
          '${realActivity['destination'] ?? _activityTitle(realActivity)}'.trim();
    }
    final dayLabel = 'Ngày ${dayIndex + 1}';
    if (firstDestination == null ||
        firstDestination.isEmpty ||
        firstDestination.startsWith('Điểm đến ngày')) {
      return dayLabel;
    }
    return '$dayLabel — $firstDestination';
  }

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lịch trình trong ngày',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _TripItineraryResultScreenState._muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _daySubtitle(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (totalDays > 1) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Ngày ${dayIndex + 1} / $totalDays',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _TripItineraryResultScreenState._muted),
                      ),
                    ],
                  ],
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
          // Nút chuyển nhanh giữa các ngày — hiển thị ngay trong card lịch trình
          // để user không phải cuộn lên đầu trang dùng DaySelector riêng.
          if (totalDays > 1 && onDayChanged != null) ...[
            _DayQuickSwitcher(
              days: days,
              selectedIndex: dayIndex,
              onChanged: onDayChanged!,
            ),
            const SizedBox(height: 14),
          ],
          if (activities.isEmpty)
            _EmptyState(onAdd: onAdd)
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
    final visual = _visualForCategory(category);

    // Độ dài line dọc tỉ lệ theo duration (phút) của activity hiện tại:
    // - activity ngắn (~30p) → line ngắn ~28px
    // - activity dài (~180p) → line dài ~80px
    // Sau đó scale theo isMajor để tham quan có line dài hơn ăn uống.
    final minutes = _durationToMinutes(duration) ?? 0;
    final baseLength = minutes > 0
        ? 28 + (minutes.clamp(0, 240) / 240) * 60
        : 40.0;
    final lineLength = baseLength * (visual.isMajor ? 1.3 : 0.85);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line and dot — màu theo category
          SizedBox(
            width: 38,
            child: Column(
              children: [
                Container(
                  width: visual.isMajor ? 34 : 30,
                  height: visual.isMajor ? 34 : 30,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: visual.isMajor ? visual.color : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: visual.color,
                      width: visual.isMajor ? 0 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: visual.color.withValues(alpha: 0.28),
                        blurRadius: visual.isMajor ? 12 : 8,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    visual.icon,
                    size: visual.isMajor ? 18 : 15,
                    color: visual.isMajor ? Colors.white : visual.color,
                  ),
                ),
                if (!isLast)
                  // SizedBox thay vì Expanded để tỉ lệ theo duration.
                  // Expanded vẫn được dùng để kéo dài hết chiều cao card bên phải
                  // (nhưng tỉ lệ tương đối dựa trên duration đã set min height).
                  Container(
                    width: 2,
                    height: lineLength,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [visual.lineColor, visual.lineColor.withValues(alpha: 0.5)],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Content card — kích thước + style theo isMajor
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: EdgeInsets.all(visual.isMajor ? 18 : 14),
              decoration: BoxDecoration(
                gradient: visual.isMajor
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [visual.bgColor, Colors.white],
                      )
                    : null,
                color: visual.isMajor ? null : Colors.white,
                borderRadius: BorderRadius.circular(visual.isMajor ? 26 : 20),
                border: Border.all(
                  color: visual.isMajor ? visual.color.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
                  width: visual.isMajor ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: visual.isMajor
                        ? visual.color.withValues(alpha: 0.12)
                        : const Color(0x080F172A),
                    blurRadius: visual.isMajor ? 24 : 16,
                    offset: Offset(0, visual.isMajor ? 10 : 6),
                  ),
                ],
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
                                _ActivityMeta(icon: visual.icon, label: category, color: visual.color),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              title,
                              style: TextStyle(
                                color: _TripItineraryResultScreenState._ink,
                                fontSize: visual.isMajor ? 17 : 15,
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
                      style: TextStyle(
                        color: visual.color,
                        fontSize: visual.isMajor ? 14 : 13,
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
                        color: visual.bgColor.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: visual.color),
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
        if (value == 'edit') onEdit();
        if (value == 'ai') onOptimize();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
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

/// Tab chuyển nhanh giữa các ngày, đặt ngay dưới header của TimelineSection.
/// Mỗi tab hiển thị "Ngày X" + số activity ngắn gọn, giúp user điều hướng
/// trong lịch trình dài nhiều ngày mà không cần cuộn lên đầu trang.
class _DayQuickSwitcher extends StatelessWidget {
  const _DayQuickSwitcher({
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
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: days.length,
        separatorBuilder: (context, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          final dayData = days[index];
          final dayNumber = dayData['day'] ?? (index + 1);
          final activityCount = _activitiesFor(dayData).length;
          return InkWell(
            onTap: () => onChanged(index),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF008F6A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF008F6A)
                      : const Color(0xFFE2E8E4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: selected ? Colors.white : const Color(0xFF15221D),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ngày $dayNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: selected ? Colors.white : const Color(0xFF15221D),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.22)
                          : const Color(0xFF15221D).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$activityCount',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: selected ? Colors.white : const Color(0xFF15221D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
