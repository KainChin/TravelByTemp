// ignore_for_file: use_string_in_part_of_directives
part of saved_trip_detail_screen;

// ─── Mini Timetable ───────────────────────────────────────────────────────────
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

  Color _color(Map<String, dynamic> a) {
    final cat = '${a['category'] ?? ''}'.toLowerCase();
    if (cat.contains('an') || cat.contains('food')) return _green;
    if (cat.contains('khách')) return const Color(0xFFF472B6);
    if (cat.contains('di chuy')) return const Color(0xFF0EA5E9);
    return _indigo;
  }

  @override
  Widget build(BuildContext context) {
    final items = activities.take(5).toList();
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionLabel(icon: Icons.schedule_rounded, label: 'Tóm tắt lịch nhanh'),
        const SizedBox(height: 14),
        ...items.asMap().entries.map((e) {
          final a = e.value;
          final isLast = e.key == items.length - 1;
          final color = _color(a);
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Icon(_icon(a), color: Colors.white, size: 20),
              ),
              if (!isLast) Container(width: 2, height: 26, margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.2)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    borderRadius: BorderRadius.circular(1),
                  )),
            ]),
            const SizedBox(width: 14),
            Expanded(child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18, top: 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
                  child: Text('${a['time'] ?? '--:--'}', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 4),
                Text('${a['activity'] ?? a['place'] ?? 'Hoạt động'}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            )),
          ]);
        }),
      ]),
    );
  }
}

// ─── Itinerary List ───────────────────────────────────────────────────────────
class _ItineraryList extends StatelessWidget {
  const _ItineraryList({required this.activities});
  final List<Map<String, dynamic>> activities;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionLabel(icon: Icons.list_alt_rounded, label: 'Lịch trình chi tiết'),
      const SizedBox(height: 14),
      if (activities.isEmpty)
        const _Empty()
      else
        ...activities.asMap().entries.map((e) =>
            _ActivityRow(index: e.key, activity: e.value, isLast: e.key == activities.length - 1)),
    ]),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.index, required this.activity, required this.isLast});
  final int index;
  final Map<String, dynamic> activity;
  final bool isLast;

  String get _fmtCost => _fmtAmount(_parseCost(activity));

  @override
  Widget build(BuildContext context) {
    final title = '${activity['activity'] ?? activity['place'] ?? 'Hoạt động'}';
    final time  = '${activity['time'] ?? '--:--'}';
    final dest  = '${activity['destination'] ?? ''}';

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 34, height: 34, alignment: Alignment.center,
            decoration: BoxDecoration(gradient: _gradIndigo, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]),
            child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
          if (!isLast) Container(width: 2, height: 26, margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_indigo.withValues(alpha: 0.4), _indigo.withValues(alpha: 0.05)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter),
                borderRadius: BorderRadius.circular(1),
              )),
        ]),
        const SizedBox(width: 12),
        Expanded(child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _line),
              boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 20, offset: Offset(0, 8))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _ink),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              const Icon(Icons.favorite_rounded, color: Color(0xFFF43F5E), size: 17),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 10, children: [
              _MetaChip(icon: Icons.schedule_outlined, label: time, color: const Color(0xFF0EA5E9)),
              _MetaChip(icon: Icons.payments_outlined, label: _fmtCost, color: const Color(0xFFF59E0B)),
              if (dest.isNotEmpty) _MetaChip(icon: Icons.place_outlined, label: dest, color: _muted),
            ]),
          ]),
        )),
      ]),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, required this.color});
  final IconData icon; final String label; final Color color;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: color),
    const SizedBox(width: 3),
    Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
  ]);
}
