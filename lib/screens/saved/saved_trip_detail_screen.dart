// ignore_for_file: unnecessary_library_name
library saved_trip_detail_screen;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:assignment/core/widgets/safe_network_image.dart';
import 'package:assignment/screens/trips/services/saved_itinerary_store.dart';
import 'package:assignment/screens/trips/screens/trip_itinerary_result_screen.dart';
import 'package:assignment/core/strings/itinerary_strings.dart';

part 'saved_trip_detail/saved_trip_tokens.dart';
part 'saved_trip_detail/saved_trip_header.dart';
part 'saved_trip_detail/saved_trip_timeline.dart';
part 'saved_trip_detail/saved_trip_budget.dart';
part 'saved_trip_detail/saved_trip_shared.dart';
part 'saved_trip_detail/saved_trip_activity_editor.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────
class SavedTripDetailScreen extends StatefulWidget {
  const SavedTripDetailScreen({super.key, required this.item});
  final SavedItineraryItem item;

  @override
  State<SavedTripDetailScreen> createState() => _SavedTripDetailScreenState();
}

class _SavedTripDetailScreenState extends State<SavedTripDetailScreen> {
  final Map<String, int> _actual = {
    'transport': 0, 'accommodation': 0, 'food': 0, 'activities': 0,
  };

  int _selectedDayIndex = 0;
  bool _savingTrip = false;
  Future<void>? _persistFuture;

  /// Local copy của itinerary để thêm/sửa/xóa activity mà không cần round-trip
  /// tới server. Sẽ được lưu vào [SavedItineraryStore] khi user back ra.
  late Map<String, dynamic> _localItinerary;
  bool _localDirty = false;

  @override
  void initState() {
    super.initState();
    _localItinerary = Map<String, dynamic>.from(widget.item.itinerary);
  }

  Map<String, dynamic> get _itinerary => _localItinerary;

  List<Map<String, dynamic>> get _days {
    final raw = _itinerary['days'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic>? get _selectedDay {
    if (_days.isEmpty) return null;
    final safe = _selectedDayIndex.clamp(0, _days.length - 1);
    return _days[safe];
  }

  /// Activities cho UI (chỉ ngày đang chọn). Dùng cho MiniTimetable, ItineraryList, MapCard.
  List<Map<String, dynamic>> get _activities {
    final day = _selectedDay;
    if (day == null) return const [];
    final raw = day['activities'] ?? day['schedule'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Activities trên toàn bộ trip (tất cả các ngày). Dùng để hiển thị tổng
  /// chi phí / số hoạt động ở Hero và tổng ngân sách ở BudgetSection để số
  /// liệu không "giật" khi user chuyển ngày.
  List<Map<String, dynamic>> get _allActivities =>
      _days.expand((d) {
        final raw = d['activities'] ?? d['schedule'];
        if (raw is! List) return const <Map<String, dynamic>>[];
        return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e));
      }).toList();

  int get _totalActivities => _allActivities.length;

  Map<String, int> get _projected {
    var transport = 0, food = 0, stay = 0, acts = 0;
    for (final a in _allActivities) {
      final cost = _parseCost(a);
      switch (_parseCategory(a)) {
        case 'ăn uống':  food += cost;
        case 'khách sạn': stay += cost;
        case 'di chuyển': transport += cost;
        default:          acts += cost;
      }
    }
    return {'transport': transport, 'food': food, 'accommodation': stay, 'activities': acts};
  }

  /// Tổng dự kiến chỉ của ngày đang chọn. Dùng để so sánh với actual hợp lý hơn.
  Map<String, int> get _dayProjected {
    var transport = 0, food = 0, stay = 0, acts = 0;
    for (final a in _activities) {
      final cost = _parseCost(a);
      switch (_parseCategory(a)) {
        case 'ăn uống':  food += cost;
        case 'khách sạn': stay += cost;
        case 'di chuyển': transport += cost;
        default:          acts += cost;
      }
    }
    return {'transport': transport, 'food': food, 'accommodation': stay, 'activities': acts};
  }

  int get _totalProjected => _projected.values.fold(0, (a, b) => a + b);
  int get _totalActual    => _actual.values.fold(0, (a, b) => a + b);

  /// Đánh dấu dirty và lưu vào SharedPreferences (best-effort).
  ///
  /// Các lần gọi nối tiếp được xếp hàng đợi để tránh hai write chạy đồng
  /// thời ghi đè lẫn nhau trong SharedPreferences (khi user thêm/xóa nhiều
  /// activity liên tiếp).
  Future<void> _persist() {
    if (!_localDirty) return Future.value();
    final prev = _persistFuture ?? Future.value();
    final next = prev.then((_) async {
      if (!_localDirty) return;
      _savingTrip = true;
      if (mounted) setState(() {});
      try {
        await SavedItineraryStore.updateItinerary(widget.item.id, _localItinerary);
        _localDirty = false;
      } finally {
        _savingTrip = false;
        if (mounted) setState(() {});
      }
    });
    _persistFuture = next;
    return next;
  }

  /// Đánh dấu local state đã thay đổi và lên lịch persist (queue).
  void _markDirty() {
    if (!mounted) return;
    setState(() => _localDirty = true);
    _persist();
  }

  void _onAddActivity() async {
    final created = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ActivityEditorSheet(
        dayIndex: _selectedDayIndex,
        existingCount: _activities.length,
      ),
    );
    if (created == null) return;
    _mutateActivities((items) => items.add(created));
  }

  void _onEditActivity(int index) async {
    if (index < 0 || index >= _activities.length) return;
    final updated = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ActivityEditorSheet(
        dayIndex: _selectedDayIndex,
        existingCount: _activities.length,
        initial: _activities[index],
        index: index,
      ),
    );
    if (updated == null) return;
    _mutateActivities((items) => items[index] = updated);
  }

  void _onDeleteActivity(int index) async {
    if (index < 0 || index >= _activities.length) return;
    final removed = _activities[index];
    _mutateActivities((items) => items.removeAt(index));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Đã xóa "${removed['activity'] ?? removed['destination'] ?? 'hoạt động'}".',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Hoàn tác',
            onPressed: () {
              _mutateActivities((items) => items.insert(index.clamp(0, items.length), removed));
            },
          ),
        ),
      );
  }

  void _mutateActivities(void Function(List<Map<String, dynamic>>) mutate) {
    final day = _selectedDay;
    if (day == null) return;
    final items = (day['activities'] ?? day['schedule'] ?? <dynamic>[])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    mutate(items);
    day['activities'] = items;
    _markDirty();
  }

  void _useAndEdit() {
    // Đảm bảo mọi thay đổi trước khi mở editor đầy đủ đã được lưu.
    if (_localDirty) {
      _persist();
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => TripItineraryResultScreen(
        response: '${_itinerary['summary'] ?? ''}',
        itinerary: Map<String, dynamic>.from(_itinerary),
        itineraryId: widget.item.id,
      ),
    )).then((_) {
      // Khi quay về, đồng bộ lại _localItinerary từ store
      if (mounted) {
        setState(() {
          _localItinerary = Map<String, dynamic>.from(widget.item.itinerary);
          _localDirty = false;
        });
      }
    });
  }

  void _share() {
    final text = SavedItineraryStore.buildShareText(widget.item);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Đã sao chép nội dung chia sẻ vào bộ nhớ tạm.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          backgroundColor: _primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: widget.item.title);
    final nextName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Đổi tên hành trình',
            style: TextStyle(fontWeight: FontWeight.w900, color: _ink)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nhập tên mới',
            filled: true,
            fillColor: _bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: _muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: _primary),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());

    if (nextName == null || nextName.isEmpty || nextName == widget.item.title) {
      return;
    }
    // Cập nhật local + persist
    setState(() {
      _localItinerary = Map<String, dynamic>.from(_localItinerary)
        ..['title'] = nextName;
      _localDirty = true;
    });
    await _persist();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Đã đổi tên thành "$nextName"'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ));
  }

  Future<void> _clone() async {
    // Tạo bản sao bằng cách thêm suffix "(Bản sao)" + id mới
    final clonedTitle = '${widget.item.title} (Bản sao)';
    final clonedId = '${widget.item.id}-copy-${DateTime.now().millisecondsSinceEpoch}';
    final cloned = Map<String, dynamic>.from(_localItinerary)
      ..['title'] = clonedTitle
      ..['id'] = clonedId;
    try {
      await SavedItineraryStore.save(cloned);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi khi sao chép: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Đã sao chép hành trình thành công!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Xem',
          onPressed: () => Navigator.pop(context, true),
        ),
      ));
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Xóa hành trình?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Bạn chắc muốn xóa "${widget.item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    // Lưu lại để có thể undo
    final removedItem = widget.item;
    final parentScaffold = ScaffoldMessenger.of(context);
    await SavedItineraryStore.remove(widget.item.id);
    if (!mounted) return;
    // Cũng nhảy các thay đổi local đang pending để tránh ghi ngược sau khi pop
    _persistFuture = null;
    Navigator.pop(context, true);

    // Show undo ở parent scaffold (sau pop this screen)
    parentScaffold
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Đã xóa "${removedItem.title}".'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Hoàn tác',
            onPressed: () async {
              await SavedItineraryStore.save(removedItem.itinerary);
              parentScaffold.showSnackBar(
                const SnackBar(
                  content: Text('Đã khôi phục hành trình.'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      );
  }

  void _addExpense(String key) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _ExpenseSheet(
        categoryLabel: _labelFor(key),
        onSave: (v) => setState(() => _actual[key] = (_actual[key] ?? 0) + v),
      ),
    );
  }

  String _dayLabel(int index) {
    if (_days.isEmpty) return 'Ngày 1';
    final day = _days[index];
    final date = '${day['date'] ?? ''}'.trim();
    if (date.isNotEmpty) return 'Ngày ${index + 1} · $date';
    return 'Ngày ${index + 1}';
  }

  /// Pull-to-refresh: đợi persist hiện tại xong rồi đồng bộ _localItinerary
  /// từ store (phòng trường hợp 2 thiết bị / server cập nhật).
  Future<void> _onRefresh() async {
    if (_localDirty) {
      // Đợi write hiện tại xong trước khi refresh
      await (_persistFuture ?? Future.value());
    }
    final fresh = await SavedItineraryStore.load();
    if (!mounted) return;
    final remote = fresh.firstWhere(
      (e) => e.id == widget.item.id,
      orElse: () => widget.item,
    );
    setState(() {
      _localItinerary = Map<String, dynamic>.from(remote.itinerary);
      _localDirty = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF7FBF8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: _primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
            _HeroHeader(
              title: widget.item.title,
              totalActivities: _totalActivities,
              allActivities: _allActivities,
              dayCount: _days.length,
              isDirty: _localDirty || _savingTrip,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
                child: Column(children: [
                  _ActionButtons(
                    onEdit: _useAndEdit,
                    onShare: _share,
                    onDelete: _delete,
                    onRename: _rename,
                    onClone: _clone,
                  )
                      .animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutBack),
                  if (_days.length > 1) ...[
                    const SizedBox(height: 18),
                    _DayNavigator(
                      days: List.generate(_days.length, _dayLabel),
                      selectedIndex: _selectedDayIndex,
                      onSelect: (i) => setState(() => _selectedDayIndex = i),
                    )
                        .animate().fadeIn(delay: 150.ms).slideY(begin: 0.15, end: 0, duration: 500.ms, curve: Curves.easeOut),
                  ],
                  const SizedBox(height: 18),
                  _MapCard(day: _selectedDay)
                      .animate().fadeIn(delay: 200.ms).slideY(begin: 0.15, end: 0, duration: 500.ms, curve: Curves.easeOut),
                  const SizedBox(height: 14),
                  _MiniTimetable(activities: _activities)
                      .animate().fadeIn(delay: 300.ms).slideY(begin: 0.15, end: 0, duration: 500.ms, curve: Curves.easeOut),
                  const SizedBox(height: 14),
                  _ItineraryList(
                    activities: _activities,
                    onAdd: _onAddActivity,
                    onEdit: _onEditActivity,
                    onDelete: _onDeleteActivity,
                  )
                      .animate().fadeIn(delay: 400.ms).slideY(begin: 0.15, end: 0, duration: 500.ms, curve: Curves.easeOut),
                  const SizedBox(height: 14),
                  _BudgetSection(
                    projected: _projected, actual: _actual,
                    totalProjected: _totalProjected, totalActual: _totalActual,
                    fmt: _fmtAmount, catIcon: _iconFor, catLabel: _labelFor,
                    catColor: _colorFor, onAddExpense: _addExpense,
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.15, end: 0, duration: 500.ms, curve: Curves.easeOut),
                  const SizedBox(height: 14),
                  const _BillScanCard()
                      .animate().fadeIn(delay: 600.ms).slideY(begin: 0.15, end: 0, duration: 500.ms, curve: Curves.easeOut),
                ]),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

// ─── Day Navigator (cho multi-day trip) ───────────────────────────────────────
/// Thanh ngang cuộn được, kèm 2 nút chevron prev/next + số "Ngày X/Y". Đặc
/// biệt hữu ích với trip nhiều ngày (>3 ngày) — user không phải scroll ngang
/// tìm pill đang chọn.
class _DayNavigator extends StatelessWidget {
  const _DayNavigator({
    required this.days,
    required this.selectedIndex,
    required this.onSelect,
  });
  final List<String> days;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final hasPrev = selectedIndex > 0;
    final hasNext = selectedIndex < days.length - 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _primarySoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Ngày ${selectedIndex + 1}/${days.length}',
            style: const TextStyle(
              color: _primary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Spacer(),
        _NavBtn(
          icon: Icons.chevron_left_rounded,
          enabled: hasPrev,
          onTap: () => onSelect(selectedIndex - 1),
        ),
        const SizedBox(width: 6),
        _NavBtn(
          icon: Icons.chevron_right_rounded,
          enabled: hasNext,
          onTap: () => onSelect(selectedIndex + 1),
        ),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final selected = i == selectedIndex;
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => onSelect(i),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: selected ? _gradPrimary : null,
                    color: selected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? Colors.transparent : _line,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : const [],
                  ),
                  child: Text(
                    days[i],
                    style: TextStyle(
                      color: selected ? Colors.white : _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? _primary : _line,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32, height: 32,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
