// ignore_for_file: unnecessary_library_name, unused_element
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

part 'saved_trip_detail/saved_trip_tokens.dart';
part 'saved_trip_detail/saved_trip_header.dart';
part 'saved_trip_detail/saved_trip_timeline.dart';
part 'saved_trip_detail/saved_trip_budget.dart';
part 'saved_trip_detail/saved_trip_shared.dart';

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

  Map<String, dynamic> get _itinerary => widget.item.itinerary;

  Map<String, dynamic>? get _firstDay {
    final raw = _itinerary['days'];
    if (raw is! List) return null;
    final days = raw.whereType<Map>().toList();
    return days.isEmpty ? null : Map<String, dynamic>.from(days.first);
  }

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

  void _useAndEdit() => Navigator.push(context, MaterialPageRoute(
    builder: (_) => TripItineraryResultScreen(
      response: '${_itinerary['summary'] ?? ''}',
      itinerary: Map<String, dynamic>.from(_itinerary),
      itineraryId: widget.item.id,
    ),
  ));

  void _share() {
    Clipboard.setData(ClipboardData(text: widget.item.title));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Đã sao chép tên hành trình để chia sẻ.'),
      backgroundColor: _indigo,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    if (ok == true && mounted) {
      await SavedItineraryStore.remove(widget.item.id);
      if (mounted) Navigator.pop(context, true);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _HeroHeader(title: widget.item.title, activities: _activities),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Column(children: [
                const SizedBox(height: 12),
                _ActionButtons(onEdit: _useAndEdit, onShare: _share, onDelete: _delete)
                    .animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 16),
                _MapCard(day: _firstDay)
                    .animate().fadeIn(delay: 200.ms).slideY(begin: 0.15, end: 0, duration: 500.ms, curve: Curves.easeOut),
                const SizedBox(height: 14),
                _MiniTimetable(activities: _activities)
                    .animate().fadeIn(delay: 300.ms).slideY(begin: 0.15, end: 0, duration: 500.ms, curve: Curves.easeOut),
                const SizedBox(height: 14),
                _ItineraryList(activities: _activities)
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
    );
  }
}
