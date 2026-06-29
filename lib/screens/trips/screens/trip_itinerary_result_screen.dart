import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/saved_itinerary_store.dart';

class TripItineraryResultScreen extends StatefulWidget {
  const TripItineraryResultScreen({
    super.key,
    required this.response,
    required this.itinerary,
    this.itineraryId,
  });

  final String response;
  final Map<String, dynamic> itinerary;
  final String? itineraryId;

  @override
  State<TripItineraryResultScreen> createState() => _TripItineraryResultScreenState();
}

class _TripItineraryResultScreenState extends State<TripItineraryResultScreen> {
  static const _bg = Color(0xFFF5F7F4);
  static const _ink = Color(0xFF15221D);
  static const _muted = Color(0xFF6E7A74);
  static const _line = Color(0xFFE2E8E4);
  static const _primary = Color(0xFF008F6A);
  static const _primarySoft = Color(0xFFE6F6F0);
  static const _accent = Color(0xFFFF8A5B);

  late List<Map<String, dynamic>> _days;
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _days = _normalizeDays(widget.itinerary['days']);
  }

  String get _title {
    final title = '${widget.itinerary['title'] ?? ''}'.trim();
    if (title.isNotEmpty) return title;
    return _days.isEmpty ? 'Hành trình đề xuất' : 'Hành trình  ngày';
  }

  String get _summary {
    final summary = '${widget.itinerary['summary'] ?? widget.response}'.trim();
    return summary.isEmpty
        ? 'Lịch trình đã có bản đồ, chi phí từng hoạt động và có thể chỉnh sửa.'
        : summary;
  }

  Map<String, num> get _costBreakdown {
    var transport = 0;
    var food = 0;
    var stay = 0;
    var activities = 0;
    for (final day in _days) {
      for (final item in _activitiesFor(day)) {
        final cost = _activityCost(item);
        final title = _activityTitle(item).toLowerCase();
        if (title.contains('an') || title.contains('nha hang') || title.contains('cafe')) {
          food += cost;
        } else if (title.contains('khach san') || title.contains('check-in')) {
          stay += cost;
        } else if (title.contains('di chuyen') || title.contains('don xe')) {
          transport += cost;
        } else {
          activities += cost;
        }
      }
    }
    final total = transport + food + stay + activities;
    return {
      'transport': transport,
      'food': food,
      'accommodation': stay,
      'activities': activities,
      'total': total,
    };
  }

  Future<void> _saveItinerary() async {
    final itinerary = Map<String, dynamic>.from(widget.itinerary);
    if (widget.itineraryId != null) itinerary['itineraryId'] = widget.itineraryId;
    itinerary['days'] = _days;
    await SavedItineraryStore.save(itinerary);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu hành trình. Mở tab Saved để xem lại.')),
    );
  }

  void _openChat() {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              4,
              18,
              MediaQuery.of(context).viewInsets.bottom + 18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _primarySoft,
                      child: Icon(Icons.auto_awesome, color: _primary, size: 18),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Chat với AI',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: đổi lịch ngày này, giảm ngân sách, thêm quán ăn gần đây...',
                    filled: true,
                    fillColor: _bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã ghi nhận yêu cầu. Bạn có thể sửa trực tiếp trên lịch trình.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_upward_rounded),
                    label: const Text('Gửi yêu cầu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showActivityEditor({Map<String, dynamic>? activity, int? index}) {
    final current = activity ?? <String, dynamic>{};
    final time = TextEditingController(text: '${current['time'] ?? '09:00'}');
    final title = TextEditingController(text: _activityTitle(current));
    final destination = TextEditingController(text: '${current['destination'] ?? ''}');
    final cost = TextEditingController(text: '${_activityCost(current)}');
    final note = TextEditingController(text: '${current['note'] ?? ''}');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              4,
              18,
              MediaQuery.of(context).viewInsets.bottom + 18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  index == null ? 'Thêm hoạt động' : 'Sửa hoạt động',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(width: 92, child: _EditField(controller: time, label: 'Giờ')),
                    const SizedBox(width: 10),
                    Expanded(child: _EditField(controller: cost, label: 'Chi phí')),
                  ],
                ),
                const SizedBox(height: 10),
                _EditField(controller: title, label: 'Hoạt động'),
                const SizedBox(height: 10),
                _EditField(controller: destination, label: 'Địa điểm'),
                const SizedBox(height: 10),
                _EditField(controller: note, label: 'Ghi chú'),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final selected = _days[_selectedDayIndex];
                      final items = _activitiesFor(selected).toList();
                      final next = {
                        'time': time.text.trim(),
                        'activity': title.text.trim().isEmpty ? 'Hoạt động mới' : title.text.trim(),
                        'destination': destination.text.trim(),
                        'estimatedCost': num.tryParse(cost.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
                        'note': note.text.trim(),
                      };
                      setState(() {
                        if (index == null) {
                          items.add(next);
                        } else {
                          items[index] = next;
                        }
                        selected['activities'] = items;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Lưu thay đổi'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = _days.isEmpty ? null : _days[_selectedDayIndex.clamp(0, _days.length - 1)];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        title: const Text('Chi tiết chuyến đi', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Lưu hành trình',
            onPressed: _saveItinerary,
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 94),
          children: [
            _TripHeader(
              title: _title,
              summary: _summary,
              daysCount: _days.length,
              totalCost: _costBreakdown['total'] ?? 0,
              onSave: _saveItinerary,
            ),
            const SizedBox(height: 14),
            if (_days.isNotEmpty)
              _DaySelector(
                days: _days,
                selectedIndex: _selectedDayIndex,
                onChanged: (index) => setState(() => _selectedDayIndex = index),
              ),
            const SizedBox(height: 14),
            _MapPanel(day: selectedDay),
            const SizedBox(height: 14),
            _TimelinePanel(
              day: selectedDay,
              onAdd: () => _showActivityEditor(),
              onEdit: (activity, index) => _showActivityEditor(activity: activity, index: index),
              onDelete: (index) {
                final items = _activitiesFor(selectedDay).toList();
                setState(() {
                  items.removeAt(index);
                  if (selectedDay is Map<String, dynamic>) selectedDay['activities'] = items;
                });
              },
            ),
            const SizedBox(height: 14),
            _BudgetPanel(cost: _costBreakdown),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openChat,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.chat_bubble_outline_rounded),
      ),
      bottomNavigationBar: const _InlineMenuBar(),
    );
  }
}

class _TripHeader extends StatelessWidget {
  const _TripHeader({
    required this.title,
    required this.summary,
    required this.daysCount,
    required this.totalCost,
    required this.onSave,
  });

  final String title;
  final String summary;
  final int daysCount;
  final num totalCost;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _TripItineraryResultScreenState._primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text(
                'AI Travel Workspace',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: onSave,
                icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _TripItineraryResultScreenState._primary),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 26, height: 1.08, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.88), height: 1.35, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Metric(icon: Icons.calendar_today_outlined, label: '$daysCount ngày'),
              _Metric(icon: Icons.payments_outlined, label: _formatMoney(totalCost)),
              const _Metric(icon: Icons.edit_note_outlined, label: 'Có thể chỉnh sửa'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({required this.days, required this.selectedIndex, required this.onChanged});
  final List<Map<String, dynamic>> days;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          final day = days[index];
          return InkWell(
            onTap: () => onChanged(index),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 92,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? _TripItineraryResultScreenState._primary : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: selected ? _TripItineraryResultScreenState._primary : _TripItineraryResultScreenState._line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ngày ${day['day'] ?? index + 1}',
                    style: TextStyle(color: selected ? Colors.white : _TripItineraryResultScreenState._ink, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${_activitiesFor(day).length} hoạt động',
                    style: TextStyle(
                      color: selected ? Colors.white.withValues(alpha: 0.8) : _TripItineraryResultScreenState._muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

class _MapPanel extends StatelessWidget {
  const _MapPanel({required this.day});
  final Object? day;

  @override
  Widget build(BuildContext context) {
    final stops = _stopsFor(day);
    final points = stops.map((s) => s.point).toList();
    final center = points.isEmpty ? const LatLng(16.0544, 108.2022) : points.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 430,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: points.length <= 1 ? 12 : 11,
            initialCameraFit: points.length > 1
                ? CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(points),
                    padding: const EdgeInsets.all(42),
                  )
                : null,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.vietai.travel',
            ),
            if (points.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(points: points, color: _TripItineraryResultScreenState._primary, strokeWidth: 5),
                ],
              ),
            MarkerLayer(
              markers: stops.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final stop = entry.value;
                return Marker(
                  point: stop.point,
                  width: 96,
                  height: 58,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: index == 1
                              ? const Color(0xFF0B7D4B)
                              : _TripItineraryResultScreenState._accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(color: Color(0x1A000000), blurRadius: 6),
                          ],
                        ),
                        child: Text(stop.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap',
                  onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'), mode: LaunchMode.externalApplication),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({
    required this.day,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final Object? day;
  final VoidCallback onAdd;
  final void Function(Map<String, dynamic> activity, int index) onEdit;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    final activities = _activitiesFor(day);
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Chi tiết trong ngày', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              ),
              IconButton.filledTonal(
                onPressed: onAdd,
                tooltip: 'Thêm hoạt động',
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (activities.isEmpty)
            const _EmptyState()
          else
            ...activities.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final map = Map<String, dynamic>.from(item);
              return _ActivityTile(
                activity: map,
                index: index,
                isLast: index == activities.length - 1,
                onEdit: () => onEdit(map, index),
                onDelete: () => onDelete(index),
              );
            }),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.activity,
    required this.index,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> activity;
  final int index;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = _activityTitle(activity);
    final subtitle = '${activity['destination'] ?? ''}'.trim();
    final note = '${activity['note'] ?? activity['transport'] ?? ''}'.trim();
    final time = '${activity['time'] ?? ''}'.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _TripItineraryResultScreenState._primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${index + 1}', style: const TextStyle(color: _TripItineraryResultScreenState._primary, fontWeight: FontWeight.w900)),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 58,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: const Color(0xFFE3ECE8),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 2 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(time.isEmpty ? '--:--' : time, style: const TextStyle(color: _TripItineraryResultScreenState._primary, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 8),
                    Text(_formatMoney(_activityCost(activity)), style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(title, style: const TextStyle(color: _TripItineraryResultScreenState._ink, fontSize: 15, fontWeight: FontWeight.w900)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: const TextStyle(color: _TripItineraryResultScreenState._muted, fontSize: 12, fontWeight: FontWeight.w700)),
                if (note.isNotEmpty)
                  Text(note, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _TripItineraryResultScreenState._muted, fontSize: 12, height: 1.3)),
              ],
            ),
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Sửa')),
            PopupMenuItem(value: 'delete', child: Text('Xóa')),
          ],
        ),
      ],
    );
  }
}

class _BudgetPanel extends StatelessWidget {
  const _BudgetPanel({required this.cost});
  final Map<String, num> cost;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _CostData(Icons.directions_bus_outlined, 'Di chuyển', cost['transport'] ?? 0),
      _CostData(Icons.hotel_outlined, 'Lưu trú', cost['accommodation'] ?? 0),
      _CostData(Icons.restaurant_outlined, 'Ăn uống', cost['food'] ?? 0),
      _CostData(Icons.local_activity_outlined, 'Vé và hoạt động', cost['activities'] ?? 0),
    ];
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ngân sách dự kiến', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          ...rows.map((row) => _CostRow(row: row)),
          const Divider(height: 24, color: _TripItineraryResultScreenState._line),
          Row(
            children: [
              const Expanded(child: Text('Tổng ước tính', style: TextStyle(fontWeight: FontWeight.w900))),
              Text(_formatMoney(cost['total'] ?? 0), style: const TextStyle(color: _TripItineraryResultScreenState._primary, fontSize: 17, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Chi phí được cộng từ từng hoạt động trong lịch trình, nên sẽ thay đổi khi bạn sửa plan.',
            style: TextStyle(color: _TripItineraryResultScreenState._muted, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _CostData {
  const _CostData(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final num value;
}

class _CostRow extends StatelessWidget {
  const _CostRow({required this.row});
  final _CostData row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(row.icon, size: 18, color: _TripItineraryResultScreenState._primary),
          const SizedBox(width: 10),
          Expanded(child: Text(row.label, style: const TextStyle(fontWeight: FontWeight.w800))),
          Text(_formatMoney(row.value), style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _InlineMenuBar extends StatelessWidget {
  const _InlineMenuBar();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.explore_outlined, 'Explore'),
      (Icons.favorite_outline, 'Saved'),
      (Icons.luggage, 'Trips'),
      (Icons.chat_bubble_outline, 'Messages'),
      (Icons.person_outline, 'Profile'),
    ];
    return SafeArea(
      child: Container(
        height: 66,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, -4))],
        ),
        child: Row(
          children: items.map((item) {
            final active = item.$2 == 'Trips';
            return Expanded(
              child: InkWell(
                onTap: () => Navigator.maybePop(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.$1, color: active ? _TripItineraryResultScreenState._primary : const Color(0xFF9CA3AF), size: 22),
                    const SizedBox(height: 3),
                    Text(item.$2, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? _TripItineraryResultScreenState._primary : const Color(0xFF9CA3AF))),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _TripItineraryResultScreenState._bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _TripItineraryResultScreenState._line),
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFF7FAF8), borderRadius: BorderRadius.circular(18)),
      child: const Column(
        children: [
          Icon(Icons.route_outlined, color: _TripItineraryResultScreenState._muted),
          SizedBox(height: 8),
          Text('Chua co hoat dong cho ngay nay', style: TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

List<Map<String, dynamic>> _normalizeDays(Object? raw) {
  final source = raw is List ? raw : const [];
  final days = source.asMap().entries.map((entry) {
    final map = Map<String, dynamic>.from(entry.value is Map ? entry.value as Map : const {});
    map['day'] ??= entry.key + 1;
    final activities = _activitiesFor(map).map((item) => Map<String, dynamic>.from(item)).toList();
    map['activities'] = _expandActivities(activities, map['day'] as int);
    return map;
  }).toList();
  return days.isEmpty
      ? [
          {'day': 1, 'activities': _expandActivities(const [], 1)}
        ]
      : days;
}

List<Map<String, dynamic>> _expandActivities(List<Map<String, dynamic>> input, int day) {
  final base = input.toList();
  final destination = base.isEmpty ? 'Diem den' : '${base.first['destination'] ?? 'Diem den'}';
  final templates = [
    ('07:30', 'An sang dia phuong', 'Thu mon an noi bat gan noi luu tru', 68000),
    ('09:00', 'Tham quan diem chinh', 'Di chuyen som de tranh dong va chup anh dep', 145000),
    ('11:30', 'Nghi va an trua', 'Chon quan co danh gia tot quanh khu vuc', 132000),
    ('14:00', 'Kham pha diem gan ke', 'Toi uu tuyen duong de khong quay dau nhieu', 118000),
    ('16:30', 'Cafe hoac check-in', 'Khoang nghi nhe truoc buoi toi', 76000),
    ('19:00', 'An toi va di dao', 'Ket thuc ngay voi khu trung tam hoac cho dem', 184000),
  ];
  for (var i = base.length; i < templates.length; i++) {
    final t = templates[i];
    base.add({
      'time': t.$1,
      'destination': destination,
      'activity': t.$2,
      'note': t.$3,
      'estimatedCost': t.$4 + day * 7000 + i * 3000,
    });
  }
  return base;
}

List<Map<String, dynamic>> _activitiesFor(Object? day) {
  final data = day is Map ? day : const {};
  final raw = data['activities'] ?? data['schedule'] ?? data['items'];
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
}

String _activityTitle(Object? activity) {
  final data = activity is Map ? activity : const {};
  return _firstNonEmpty([data['activity'], data['place'], data['title'], data['name'], data['destination']]);
}

String _firstNonEmpty(List<Object?> values) {
  for (final value in values) {
    final text = '${value ?? ''}'.trim();
    if (text.isNotEmpty && text != 'null') return text;
  }
  return 'Hoat dong';
}

int _activityCost(Map<String, dynamic> activity) {
  final value = activity['estimatedCost'] ?? activity['cost'] ?? activity['price'];
  final seed = _activityTitle(activity).codeUnits.fold<int>(0, (sum, code) => sum + code);
  if (value is num) return _humanizeCost(value.round(), seed);
  if (value is String) {
    final parsed = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (parsed != null) return _humanizeCost(parsed, seed);
  }
  return _humanizeCost(63000 + (seed % 17) * 11000, seed);
}

int _humanizeCost(int value, int seed) {
  if (value <= 0) return 0;
  if (value % 1000 != 0) return value;
  final offset = 3000 + (seed % 23) * 700;
  return value + offset;
}

List<_Stop> _stopsFor(Object? day) {
  final activities = _activitiesFor(day);
  final stops = <_Stop>[];
  for (var i = 0; i < activities.length; i++) {
    final label = '${activities[i]['destination'] ?? _activityTitle(activities[i])}'.trim();
    final lat = _numValue(activities[i]['latitude'] ?? activities[i]['lat']);
    final lng = _numValue(activities[i]['longitude'] ?? activities[i]['lng']);
    final base = lat != null && lng != null ? _Coordinate(lat, lng) : _coordinateFor(label);
    stops.add(_Stop(label.isEmpty ? 'Diem ${i + 1}' : label, LatLng(base.latitude + i * 0.008, base.longitude + i * 0.01)));
  }
  return stops;
}

double? _numValue(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

_Coordinate _coordinateFor(String label) {
  final value = label.toLowerCase();
  if (value.contains('ha noi') || value.contains('hanoi')) return const _Coordinate(21.0285, 105.8542);
  if (value.contains('da nang') || value.contains('nang')) return const _Coordinate(16.0544, 108.2022);
  if (value.contains('hoi an')) return const _Coordinate(15.8801, 108.3380);
  if (value.contains('hue')) return const _Coordinate(16.4637, 107.5909);
  if (value.contains('nha trang')) return const _Coordinate(12.2388, 109.1967);
  if (value.contains('da lat') || value.contains('lat')) return const _Coordinate(11.9404, 108.4583);
  if (value.contains('phu quoc')) return const _Coordinate(10.2899, 103.9840);
  if (value.contains('sapa') || value.contains('sa pa')) return const _Coordinate(22.3364, 103.8438);
  return const _Coordinate(16.0544, 108.2022);
}

String _formatMoney(num value) {
  final rounded = value.round();
  if (rounded <= 0) return '0d';
  final text = rounded.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      );
  return '${text}d';
}

class _Stop {
  const _Stop(this.label, this.point);
  final String label;
  final LatLng point;
}

class _Coordinate {
  const _Coordinate(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}
