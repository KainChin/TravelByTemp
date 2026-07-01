import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:assignment/screens/trips/services/saved_itinerary_store.dart';
import 'package:assignment/screens/trips/screens/trip_itinerary_result_screen.dart';

// ─── Constants ───────────────────────────────────────────────────────────────
const _bg = Color(0xFFF5F7F4);
const _ink = Color(0xFF15221D);
const _muted = Color(0xFF6E7A74);
const _line = Color(0xFFE2E8E4);
const _primary = Color(0xFF008F6A);
const _primarySoft = Color(0xFFE6F6F0);

// ─── Screen ──────────────────────────────────────────────────────────────────
class SavedTripDetailScreen extends StatefulWidget {
  const SavedTripDetailScreen({super.key, required this.item});
  final SavedItineraryItem item;

  @override
  State<SavedTripDetailScreen> createState() => _SavedTripDetailScreenState();
}

class _SavedTripDetailScreenState extends State<SavedTripDetailScreen> {
  // Actual expenditure mock state (can be replaced with persistence)
  final Map<String, int> _actual = {
    'transport': 0,
    'accommodation': 0,
    'food': 0,
    'activities': 0,
  };

  Map<String, dynamic> get _itinerary => widget.item.itinerary;

  List<Map<String, dynamic>> get _days {
    final raw = _itinerary['days'];
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic>? get _firstDay => _days.isEmpty ? null : _days.first;

  List<Map<String, dynamic>> get _activities {
    final day = _firstDay;
    if (day == null) return [];
    final raw = day['activities'] ?? day['schedule'];
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, int> get _projected {
    var transport = 0, food = 0, stay = 0, acts = 0;
    for (final a in _activities) {
      final cost = _cost(a);
      final cat = _cat(a);
      if (cat == 'ăn uống') {
        food += cost;
      } else if (cat == 'khách sạn') {
        stay += cost;
      } else if (cat == 'di chuyển') {
        transport += cost;
      } else {
        acts += cost;
      }
    }
    return {'transport': transport, 'food': food, 'accommodation': stay, 'activities': acts};
  }

  int get _totalProjected => _projected.values.fold(0, (a, b) => a + b);
  int get _totalActual => _actual.values.fold(0, (a, b) => a + b);

  int _cost(Map<String, dynamic> a) {
    final v = a['estimatedCost'] ?? a['cost'] ?? 0;
    if (v is num) return v.round();
    final parsed = int.tryParse('$v'.replaceAll(RegExp(r'[^0-9]'), ''));
    return parsed ?? 0;
  }

  String _cat(Map<String, dynamic> a) {
    final raw = '${a['category'] ?? a['type'] ?? ''}'.toLowerCase();
    if (raw.contains('an') || raw.contains('food')) return 'ăn uống';
    if (raw.contains('hotel') || raw.contains('khách')) return 'khách sạn';
    if (raw.contains('transport') || raw.contains('di chuyển')) return 'di chuyển';
    return 'tham quan';
  }

  String _fmt(int v) {
    if (v <= 0) return '0đ';
    return '${v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
  }

  IconData _catIcon(String key) => switch (key) {
        'transport' => Icons.directions_bus_outlined,
        'accommodation' => Icons.hotel_outlined,
        'food' => Icons.restaurant_outlined,
        _ => Icons.local_activity_outlined,
      };

  String _catLabel(String key) => switch (key) {
        'transport' => 'Di chuyển',
        'accommodation' => 'Lưu trú',
        'food' => 'Ăn uống',
        _ => 'Vé & Hoạt động',
      };

  // ── Actions ──
  void _useAndEdit() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => TripItineraryResultScreen(
        response: '${_itinerary['summary'] ?? ''}',
        itinerary: Map<String, dynamic>.from(_itinerary),
        itineraryId: widget.item.id,
      ),
    ));
  }

  void _share() {
    final title = widget.item.title;
    Clipboard.setData(ClipboardData(text: title));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép tên hành trình để chia sẻ.')),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa hành trình?'),
        content: Text('Bạn chắc muốn xóa "${widget.item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await SavedItineraryStore.remove(widget.item.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  void _showAddExpense(String key) {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Nhập chi tiêu thực tế – ${_catLabel(key)}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Số tiền (VNĐ)',
              filled: true,
              fillColor: _bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              suffixText: 'đ',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                final v = int.tryParse(ctrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                setState(() => _actual[key] = (_actual[key] ?? 0) + v);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Lưu'),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          _HeroHeader(title: widget.item.title, activities: _activities),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Column(children: [
                const SizedBox(height: 14),
                _ActionButtons(onEdit: _useAndEdit, onShare: _share, onDelete: _delete),
                const SizedBox(height: 16),
                _MapCard(day: _firstDay),
                const SizedBox(height: 14),
                _MiniTimetable(activities: _activities),
                const SizedBox(height: 14),
                _ItineraryList(activities: _activities),
                const SizedBox(height: 14),
                _BudgetCards(
                  projected: _projected,
                  actual: _actual,
                  totalProjected: _totalProjected,
                  totalActual: _totalActual,
                  fmt: _fmt,
                  catIcon: _catIcon,
                  catLabel: _catLabel,
                  onAddExpense: _showAddExpense,
                ),
                const SizedBox(height: 14),
                _BillScanCard(),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _SavedBottomNav(),
    );
  }
}

// ─── Hero Header ─────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.title, required this.activities});
  final String title;
  final List<Map<String, dynamic>> activities;

  int get _totalCost => activities.fold(0, (s, a) {
        final v = a['estimatedCost'] ?? 0;
        return s + (v is num ? v.round() : 0);
      });

  String _fmt(int v) =>
      '${v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient tropical background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B5C3E), Color(0xFF00A879), Color(0xFF43C6AC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Decorative circles
            Positioned(right: -40, top: -40,
              child: Container(width: 180, height: 180,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07)))),
            Positioned(left: -30, bottom: 20,
              child: Container(width: 120, height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05)))),
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 56, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.bookmark, size: 13, color: Colors.white),
                        SizedBox(width: 5),
                        Text('Đã lưu', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    Text(title,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.15),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _StatBadge('${activities.isEmpty ? 1 : 1} ngày'),
                      _StatBadge('${activities.length} hoạt động'),
                      _StatBadge(_fmt(_totalCost)),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}

// ─── Action Buttons ──────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onEdit, required this.onShare, required this.onDelete});
  final VoidCallback onEdit, onShare, onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Row(children: [
        _ActionBtn(label: 'Sửa & Dùng', icon: Icons.edit_note_rounded,
            color: _primary, onTap: onEdit),
        const SizedBox(width: 8),
        _ActionBtn(label: 'Chat AI', icon: Icons.camera_alt_outlined,
            color: const Color(0xFF7C3AED), onTap: () {}),
        const SizedBox(width: 8),
        _ActionBtn(label: 'Chia sẻ', icon: Icons.ios_share_rounded,
            color: const Color(0xFF2563EB), onTap: onShare),
        const SizedBox(width: 8),
        _ActionBtn(label: 'Xóa', icon: Icons.delete_outline_rounded,
            color: Colors.redAccent, onTap: onDelete),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.label, required this.icon, required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

// ─── Map Card ────────────────────────────────────────────────────────────────
class _MapCard extends StatelessWidget {
  const _MapCard({required this.day});
  final Map<String, dynamic>? day;

  static const _daNang = LatLng(16.0544, 108.2022);
  static const _phuQuoc = LatLng(10.2899, 103.9840);

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionLabel(icon: Icons.map_outlined, label: 'Bản đồ hành trình'),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 200,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(13.0, 106.0),
                initialZoom: 5.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.vietai.travel',
                ),
                PolylineLayer(polylines: [
                  Polyline(points: const [_daNang, _phuQuoc],
                      color: _primary, strokeWidth: 3,
                      pattern: StrokePattern.dashed(segments: [10, 6])),
                ]),
                MarkerLayer(markers: [
                  _marker(_daNang, 'ĐN', Colors.orange),
                  _marker(_phuQuoc, 'PQ', _primary),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.flight_takeoff_rounded, size: 14, color: _muted),
          const SizedBox(width: 6),
          Text('Chuyến bay (Ngày 1: Đà Nẵng → Phú Quốc)',
              style: const TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }

  Marker _marker(LatLng point, String label, Color color) => Marker(
        point: point, width: 50, height: 50,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
          ),
          Container(width: 2, height: 8, color: color),
        ]),
      );
}

// ─── Mini Timetable ──────────────────────────────────────────────────────────
class _MiniTimetable extends StatelessWidget {
  const _MiniTimetable({required this.activities});
  final List<Map<String, dynamic>> activities;

  IconData _icon(Map<String, dynamic> a) {
    final cat = '${a['category'] ?? ''}'.toLowerCase();
    if (cat.contains('an') || cat.contains('food')) return Icons.restaurant_rounded;
    if (cat.contains('khách') || cat.contains('hotel')) return Icons.hotel_rounded;
    if (cat.contains('di chuy')) return Icons.directions_bus_rounded;
    return Icons.explore_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final items = activities.take(5).toList();
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionLabel(icon: Icons.schedule_rounded, label: 'Tóm tắt lịch trình nhanh'),
        const SizedBox(height: 10),
        ...items.asMap().entries.map((e) {
          final a = e.value;
          final isLast = e.key == items.length - 1;
          final time = '${a['time'] ?? '--:--'}';
          final title = '${a['activity'] ?? a['place'] ?? 'Hoạt động'}';
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: _primarySoft, borderRadius: BorderRadius.circular(10)),
                child: Icon(_icon(a), color: _primary, size: 18),
              ),
              if (!isLast) Container(width: 2, height: 22, color: _line),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(time, style: const TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w700)),
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ),
          ]);
        }),
      ]),
    );
  }
}

// ─── Itinerary List (with filled hearts) ─────────────────────────────────────
class _ItineraryList extends StatelessWidget {
  const _ItineraryList({required this.activities});
  final List<Map<String, dynamic>> activities;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionLabel(icon: Icons.list_alt_rounded, label: 'Lịch trình chi tiết'),
        const SizedBox(height: 10),
        if (activities.isEmpty)
          const _Empty()
        else
          ...activities.asMap().entries.map((e) => _ActivityRow(
                index: e.key,
                activity: e.value,
                isLast: e.key == activities.length - 1,
              )),
      ]),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.index, required this.activity, required this.isLast});
  final int index;
  final Map<String, dynamic> activity;
  final bool isLast;

  int get _cost {
    final v = activity['estimatedCost'] ?? 0;
    return v is num ? v.round() : 0;
  }
  String get _fmtCost =>
      '${_cost.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';

  @override
  Widget build(BuildContext context) {
    final title = '${activity['activity'] ?? activity['place'] ?? 'Hoạt động'}';
    final time = '${activity['time'] ?? '--:--'}';
    final dest = '${activity['destination'] ?? ''}';

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Step number
        Container(
          width: 30, height: 30, alignment: Alignment.center,
          decoration: BoxDecoration(color: _primarySoft, borderRadius: BorderRadius.circular(10)),
          child: Text('${index + 1}', style: const TextStyle(color: _primary, fontWeight: FontWeight.w900, fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _ink),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              // Pre-filled heart = already saved
              const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 16),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.schedule_outlined, size: 12, color: _muted),
              const SizedBox(width: 3),
              Text(time, style: const TextStyle(fontSize: 11, color: _muted)),
              const SizedBox(width: 10),
              const Icon(Icons.payments_outlined, size: 12, color: _muted),
              const SizedBox(width: 3),
              Text(_fmtCost, style: const TextStyle(fontSize: 11, color: _muted)),
              if (dest.isNotEmpty) ...[
                const SizedBox(width: 10),
                const Icon(Icons.place_outlined, size: 12, color: _muted),
                const SizedBox(width: 3),
                Expanded(child: Text(dest,
                    style: const TextStyle(fontSize: 11, color: _muted),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ─── Budget Cards ─────────────────────────────────────────────────────────────
class _BudgetCards extends StatelessWidget {
  const _BudgetCards({
    required this.projected,
    required this.actual,
    required this.totalProjected,
    required this.totalActual,
    required this.fmt,
    required this.catIcon,
    required this.catLabel,
    required this.onAddExpense,
  });
  final Map<String, int> projected;
  final Map<String, int> actual;
  final int totalProjected, totalActual;
  final String Function(int) fmt;
  final IconData Function(String) catIcon;
  final String Function(String) catLabel;
  final void Function(String) onAddExpense;

  @override
  Widget build(BuildContext context) {
    final keys = ['transport', 'accommodation', 'food', 'activities'];
    return Column(children: [
      // Projected Budget
      _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _SectionLabel(icon: Icons.account_balance_wallet_outlined, label: 'Ngân sách Dự kiến'),
          const SizedBox(height: 10),
          _TotalRow(label: 'Tổng dự kiến', value: fmt(totalProjected), color: _primary),
          const SizedBox(height: 10),
          ...keys.map((k) => _BudgetBar(
                icon: catIcon(k), label: catLabel(k),
                value: projected[k] ?? 0, total: totalProjected,
                color: _primary, fmt: fmt,
              )),
        ]),
      ),
      const SizedBox(height: 12),
      // Actual Expenditure
      _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: const _SectionLabel(icon: Icons.receipt_long_outlined, label: 'Chi tiêu Thực tế')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: totalActual > totalProjected
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                totalActual > totalProjected ? 'Vượt ngân sách' : 'Trong ngân sách',
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w800,
                  color: totalActual > totalProjected ? Colors.red : _primary,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          _TotalRow(label: 'Tổng thực tế', value: fmt(totalActual),
              color: totalActual > totalProjected ? Colors.redAccent : const Color(0xFF2563EB)),
          const SizedBox(height: 10),
          ...keys.map((k) => _ActualBar(
                icon: catIcon(k), label: catLabel(k),
                actual: actual[k] ?? 0, projected: projected[k] ?? 0,
                fmt: fmt, onAdd: () => onAddExpense(k),
              )),
        ]),
      ),
    ]);
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: _muted, fontSize: 13)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 16)),
      ]),
    );
  }
}

class _BudgetBar extends StatelessWidget {
  const _BudgetBar({
    required this.icon, required this.label,
    required this.value, required this.total,
    required this.color, required this.fmt,
  });
  final IconData icon;
  final String label;
  final int value, total;
  final Color color;
  final String Function(int) fmt;

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(children: [
        Row(children: [
          Icon(icon, size: 14, color: _muted),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
          Text(fmt(value), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio, minHeight: 6,
            backgroundColor: _line, color: color,
          ),
        ),
      ]),
    );
  }
}

class _ActualBar extends StatelessWidget {
  const _ActualBar({
    required this.icon, required this.label,
    required this.actual, required this.projected,
    required this.fmt, required this.onAdd,
  });
  final IconData icon;
  final String label;
  final int actual, projected;
  final String Function(int) fmt;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ratio = projected > 0 ? (actual / projected).clamp(0.0, 1.0) : 0.0;
    final over = actual > projected;
    final barColor = over ? Colors.redAccent : const Color(0xFF2563EB);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(children: [
        Row(children: [
          Icon(icon, size: 14, color: _muted),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
          Text(fmt(actual), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: barColor)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(color: _primarySoft, shape: BoxShape.circle),
              child: const Icon(Icons.add, size: 14, color: _primary),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio, minHeight: 6,
            backgroundColor: _line, color: barColor,
          ),
        ),
        if (projected > 0)
          Align(
            alignment: Alignment.centerRight,
            child: Text('/ ${fmt(projected)}',
                style: const TextStyle(fontSize: 10, color: _muted)),
          ),
      ]),
    );
  }
}

// ─── Bill Scan Card ───────────────────────────────────────────────────────────
class _BillScanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.document_scanner_outlined, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Phân tích & Scan Bill',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
            SizedBox(height: 4),
            Text('Chụp/Tải hóa đơn để AI cập nhật chi tiêu thực tế tự động.',
                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
          ]),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('Scan', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w900, fontSize: 12)),
        ),
      ]),
    );
  }
}

// ─── Bottom Nav (Saved active) ────────────────────────────────────────────────
class _SavedBottomNav extends StatelessWidget {
  const _SavedBottomNav();

  static const _items = [
    (Icons.explore_outlined, Icons.explore, 'Explore'),
    (Icons.favorite_border, Icons.favorite, 'Saved'),
    (Icons.luggage_outlined, Icons.luggage, 'Trips'),
    (Icons.chat_bubble_outline, Icons.chat_bubble, 'Messages'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, -4))],
        ),
        child: Row(
          children: _items.map((item) {
            final active = item.$3 == 'Saved';
            return Expanded(
              child: InkWell(
                onTap: active ? null : () => Navigator.maybePop(context),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(active ? item.$2 : item.$1,
                      color: active ? _primary : const Color(0xFF9CA3AF), size: 22),
                  const SizedBox(height: 3),
                  Text(item.$3,
                      style: TextStyle(
                        fontSize: 10, fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                        color: active ? _primary : const Color(0xFF9CA3AF),
                      )),
                  if (active)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 18, height: 2.5,
                      decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(999)),
                    ),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: _primary),
      const SizedBox(width: 7),
      Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _ink)),
    ]);
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Chưa có hoạt động', style: TextStyle(color: _muted)),
      ),
    );
  }
}
