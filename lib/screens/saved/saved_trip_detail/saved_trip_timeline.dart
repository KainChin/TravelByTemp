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
    final total = activities.length;
    final items = activities.take(5).toList();
    final hasMore = total > items.length;
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel(
          icon: Icons.schedule_rounded,
          label: 'Tóm tắt lịch nhanh',
          trailing: hasMore
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Xem tất cả $total',
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Chưa có hoạt động để tóm tắt.',
                  style: TextStyle(color: _muted, fontSize: 13)),
            ),
          )
        else
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
        if (hasMore) ...[
          const SizedBox(height: 6),
          // Vạch phân cách mỏng + hint dạng pill ở footer
          const Divider(height: 1, color: _line),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_downward_rounded, size: 14, color: _muted),
              const SizedBox(width: 6),
              Text(
                'Còn ${total - items.length} hoạt động nữa ở "Lịch trình chi tiết" phía dưới',
                style: const TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ]),
    );
  }
}

// ─── Itinerary List ───────────────────────────────────────────────────────────
class _ItineraryList extends StatelessWidget {
  const _ItineraryList({
    required this.activities,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });
  final List<Map<String, dynamic>> activities;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionLabel(
        icon: Icons.list_alt_rounded,
        label: 'Lịch trình chi tiết',
        trailing: _AddButton(onTap: onAdd),
      ),
      const SizedBox(height: 14),
      if (activities.isEmpty)
        const _Empty()
      else
        ...activities.asMap().entries.map((e) =>
            _ActivityRow(
              index: e.key,
              activity: e.value,
              isLast: e.key == activities.length - 1,
              onEdit: () => onEdit(e.key),
              onDelete: () => onDelete(e.key),
            )),
    ]),
  );
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: _gradPrimary,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text('Thêm', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.index,
    required this.activity,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
  });
  final int index;
  final Map<String, dynamic> activity;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String get _fmtCost => _fmtAmount(_parseCost(activity));

  Future<void> _showMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      onEdit();
      return;
    }
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) {
      onEdit();
      return;
    }
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset(box.size.width - 40, 30), ancestor: overlay),
        box.localToGlobal(Offset(box.size.width, 30), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final choice = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: const [
        PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 10), Text('Chỉnh sửa')])),
        PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18), SizedBox(width: 10), Text('Xóa', style: TextStyle(color: Colors.red))])),
      ],
    );
    if (choice == 'edit') onEdit();
    if (choice == 'delete') onDelete();
  }

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
            decoration: BoxDecoration(
              gradient: _gradPrimary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text('${index + 1}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
          if (!isLast) Container(
            width: 2,
            height: 26,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary.withValues(alpha: 0.4), _primary.withValues(alpha: 0.05)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ]),
        const SizedBox(width: 12),
        Expanded(child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFBFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line, width: 1),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _ink),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              GestureDetector(
                onTap: () => _showMenu(context),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _line.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert_rounded, size: 14, color: _muted),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 4, children: [
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
