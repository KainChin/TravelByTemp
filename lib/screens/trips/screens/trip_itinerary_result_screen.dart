// ignore_for_file: unnecessary_library_name

library trip_itinerary_result_screen;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';

import '../../saved/saved_screen.dart';
import '../services/saved_itinerary_store.dart';
import '../services/trip_itinerary_service.dart';

part 'itinerary_result/trip_itinerary_result_overview.dart';
part 'itinerary_result/trip_itinerary_result_map.dart';
part 'itinerary_result/trip_itinerary_result_timeline.dart';
part 'itinerary_result/trip_itinerary_result_budget.dart';
part 'itinerary_result/trip_itinerary_result_insights.dart';
part 'itinerary_result/trip_itinerary_result_ai_chat.dart';
part 'itinerary_result/trip_itinerary_result_common.dart';
part 'itinerary_result/trip_itinerary_result_schedule_helpers.dart';
part 'itinerary_result/trip_itinerary_result_budget_helpers.dart';
part 'itinerary_result/trip_itinerary_result_activity_helpers.dart';
part 'itinerary_result/trip_itinerary_result_ai_helpers.dart';
part 'itinerary_result/trip_itinerary_result_location_helpers.dart';

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
    return _days.isEmpty ? 'Hành trình đề xuất' : 'Hành trình theo ngày';
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
        final category = _activityCategory(item);
        if (category == 'ăn uống') {
          food += cost;
        } else if (category == 'khách sạn') {
          stay += cost;
        } else if (category == 'di chuyển') {
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

  num? get _userBudget => _readBudget(widget.itinerary);

  int get _totalActivities => _days.fold(0, (sum, day) => sum + _activitiesFor(day).length);

  int get _destinationCount {
    final names = <String>{};
    for (final day in _days) {
      for (final activity in _activitiesFor(day)) {
        final destination = '${activity['destination'] ?? ''}'.trim();
        if (destination.isNotEmpty && destination != 'null') names.add(destination);
      }
    }
    return names.length;
  }

  double get _aiScore {
    var score = 8.2;
    if (_totalActivities >= _days.length * 5) score += 0.4;
    if ((_costBreakdown['total'] ?? 0) > 0) score += 0.3;
    if (_days.any((day) => _activitiesFor(day).any((item) => _activityCategory(item) == 'di chuyển'))) {
      score += 0.2;
    }
    return score.clamp(7.5, 9.6).toDouble();
  }

  String get _tripStatus {
    if (_days.any((day) => _activitiesFor(day).any((item) => '${item['optimized'] ?? ''}' == 'true'))) {
      return 'Đã tối ưu';
    }
    if (_days.isNotEmpty && _days.every((day) => _activitiesFor(day).isNotEmpty)) {
      return 'Đang lên kế hoạch';
    }
    return 'Đã hoàn thành';
  }

  Future<void> _saveItinerary() async {
    final itinerary = Map<String, dynamic>.from(widget.itinerary);
    if (widget.itineraryId != null) itinerary['itineraryId'] = widget.itineraryId;
    itinerary['days'] = _days;
    var savedToDatabase = false;
    final token = VietaiScope.of(context).auth?.accessToken;
    try {
      final remote = await TripItineraryService(authToken: token).saveItinerary(
        itineraryId: widget.itineraryId,
        itinerary: itinerary,
      );
      itinerary['id'] = remote.id;
      itinerary['itineraryId'] = remote.id;
      savedToDatabase = true;
    } on TripItineraryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chưa lưu được lên database, app sẽ lưu tạm local. $e')),
      );
    }
    await SavedItineraryStore.save(itinerary);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(savedToDatabase ? 'Đã lưu hành trình lên database.' : 'Đã lưu tạm hành trình trên máy.'),
      ),
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedScreen(refreshToken: DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  void _openChat({String? initialPrompt}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        final day = _days.isEmpty ? null : _days[_selectedDayIndex];
        return _AiChatSheet(
          title: _title,
          dayLabel: day == null ? 'Chưa chọn ngày' : 'Ngày ${day['day'] ?? _selectedDayIndex + 1}',
          budgetLabel: _budgetLabel(_userBudget),
          initialPrompt: initialPrompt,
          onApply: (changes) {
            _applyAiChanges(changes);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _applyAiChanges(List<_AiChange> changes) {
    if (_days.isEmpty || changes.isEmpty) return;
    final selected = _days[_selectedDayIndex];
    final items = _activitiesFor(selected).toList();
    setState(() {
      for (final change in changes) {
        if (change.kind == _AiChangeKind.reduceCost) {
          for (final item in items) {
            final current = _activityCost(item);
            item['estimatedCost'] = (current * 0.88).round();
          }
        } else if (change.kind == _AiChangeKind.addFood) {
          items.add(_newActivity('restaurant'));
        } else if (change.kind == _AiChangeKind.addHotel) {
          items.add(_newActivity('hotel'));
        } else if (change.kind == _AiChangeKind.addPlace) {
          items.add(_newActivity('place'));
        } else if (change.kind == _AiChangeKind.transport) {
          items.add(_newActivity('transport'));
        }
      }
      selected['activities'] = items;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã áp dụng thay đổi AI vào lịch trình.')),
    );
  }

  void _showActivityEditor({Map<String, dynamic>? activity, int? index, String kind = 'activity'}) {
    final current = activity ?? <String, dynamic>{};
    final time = TextEditingController(text: '${current['time'] ?? '09:00'}');
    final title = TextEditingController(text: _activityTitle(current));
    final destination = TextEditingController(text: '${current['destination'] ?? ''}');
    final cost = TextEditingController(text: '${_activityCost(current)}');
    final note = TextEditingController(text: '${current['note'] ?? ''}');
    final address = TextEditingController(text: '${current['address'] ?? ''}');
    final duration = TextEditingController(text: '${current['duration'] ?? current['durationMinutes'] ?? ''}');
    var category = '${current['category'] ?? current['type'] ?? _categoryFromAddKind(kind)}';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return SafeArea(
            child: SingleChildScrollView(
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
                    index == null ? 'Thêm ${_addKindLabel(kind).toLowerCase()}' : 'Sửa hoạt động',
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
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    items: const [
                      DropdownMenuItem(value: 'tham quan', child: Text('Tham quan')),
                      DropdownMenuItem(value: 'ăn uống', child: Text('Ăn uống')),
                      DropdownMenuItem(value: 'khách sạn', child: Text('Khách sạn')),
                      DropdownMenuItem(value: 'di chuyển', child: Text('Di chuyển')),
                    ],
                    onChanged: (value) {
                      if (value != null) setModalState(() => category = value);
                    },
                    decoration: InputDecoration(
                      labelText: 'Danh mục',
                      filled: true,
                      fillColor: _bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _EditField(controller: title, label: 'Hoạt động'),
                  const SizedBox(height: 10),
                  _EditField(controller: destination, label: 'Địa điểm'),
                  const SizedBox(height: 10),
                  _EditField(controller: address, label: 'Địa chỉ'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _EditField(controller: duration, label: 'Thời lượng')),
                      const SizedBox(width: 10),
                      Expanded(child: _EditField(controller: note, label: 'Ghi chú')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final selected = _days[_selectedDayIndex];
                        final items = _activitiesFor(selected).toList();
                        final next = {
                          ...current,
                          'time': time.text.trim(),
                          'activity': title.text.trim().isEmpty ? _addKindLabel(kind) : title.text.trim(),
                          'destination': destination.text.trim(),
                          'address': address.text.trim(),
                          'duration': duration.text.trim(),
                          'category': category,
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
        });
      },
    );
  }

  void _showAddMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Thêm vào lịch trình', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              _AddMenuItem(icon: Icons.place_outlined, label: 'Thêm địa điểm', onTap: () => _openAddKind(context, 'place')),
              _AddMenuItem(icon: Icons.restaurant_outlined, label: 'Thêm nhà hàng', onTap: () => _openAddKind(context, 'restaurant')),
              _AddMenuItem(icon: Icons.hotel_outlined, label: 'Thêm khách sạn', onTap: () => _openAddKind(context, 'hotel')),
              _AddMenuItem(icon: Icons.local_activity_outlined, label: 'Thêm hoạt động', onTap: () => _openAddKind(context, 'activity')),
              _AddMenuItem(icon: Icons.directions_bus_outlined, label: 'Thêm phương tiện di chuyển', onTap: () => _openAddKind(context, 'transport')),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddKind(BuildContext sheetContext, String kind) {
    Navigator.pop(sheetContext);
    _showActivityEditor(kind: kind);
  }

  void _navigateSelectedDay() {
    if (_days.isEmpty) {
      _showSnack('Chưa có ngày nào để điều hướng.');
      return;
    }
    final activities = _activitiesFor(_days[_selectedDayIndex]);
    if (activities.isEmpty) {
      _showSnack('Ngày này chưa có địa điểm để điều hướng.');
      return;
    }
    _openMaps(Map<String, dynamic>.from(activities.first));
  }

  Future<void> _shareTrip() async {
    await Clipboard.setData(ClipboardData(text: '$_title\n$_summary'));
    if (!mounted) return;
    _showSnack('Đã sao chép thông tin chuyến đi để chia sẻ.');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
            tooltip: 'Luu hành trình',
            onPressed: _saveItinerary,
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final mapHeight = (MediaQuery.sizeOf(context).height * (isWide ? 0.38 : 0.36)).clamp(320.0, 460.0);
                final timeline = TimelineSection(
                  day: selectedDay,
                  onAdd: _showAddMenu,
                  onEdit: (activity, index) => _showActivityEditor(activity: activity, index: index),
                  onOptimize: (activity, index) => _openChat(
                    initialPrompt: 'Tối ưu lại hoạt động: ${_activityTitle(activity)}',
                  ),
                  onDelete: (index) {
                    final items = _activitiesFor(selectedDay).toList();
                    setState(() {
                      items.removeAt(index);
                      if (selectedDay is Map<String, dynamic>) selectedDay['activities'] = items;
                    });
                  },
                );
                final sideSections = Column(
                  children: [
                    BudgetSection(
                      cost: _costBreakdown,
                      userBudget: _userBudget,
                      onOptimizeBudget: () => _openChat(initialPrompt: 'Tối ưu ngân sách chuyến đi'),
                      onSetupBudget: () => _openChat(initialPrompt: 'Thiết lập ngân sách cho chuyến đi này'),
                    ),
                    const SizedBox(height: 14),
                    const AiInsightSection(),
                  ],
                );

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 94),
                  children: [
                    TripHeroHeader(
                      title: _title,
                      summary: _summary,
                      daysCount: _days.length,
                      destinationCount: _destinationCount,
                      activitiesCount: _totalActivities,
                      totalCost: _costBreakdown['total'] ?? 0,
                      aiScore: _aiScore,
                      status: _tripStatus,
                    ),
                    const SizedBox(height: 12),
                    QuickActions(
                      onNavigate: _navigateSelectedDay,
                      onEdit: () => _showActivityEditor(),
                      onOptimize: () => _openChat(initialPrompt: 'Tối ưu lịch trình chuyến đi'),
                      onShare: _shareTrip,
                      onSave: _saveItinerary,
                    ),
                    const SizedBox(height: 14),
                    if (_days.isNotEmpty)
                      DaySelector(
                        days: _days,
                        selectedIndex: _selectedDayIndex,
                        onChanged: (index) => setState(() => _selectedDayIndex = index),
                      ),
                    const SizedBox(height: 14),
                    TripMapSection(day: selectedDay, height: mapHeight),
                    const SizedBox(height: 14),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: timeline),
                          const SizedBox(width: 14),
                          Expanded(flex: 5, child: sideSections),
                        ],
                      )
                    else ...[
                      timeline,
                      const SizedBox(height: 14),
                      sideSections,
                    ],
                  ],
                );
              },
            ),
          ),
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






