// ignore_for_file: use_string_in_part_of_directives

part of saved_trip_detail_screen;

/// Bottom sheet thêm / sửa 1 hoạt động trong trang đã lưu.
/// Trả về map activity mới qua `Navigator.pop`; nếu user đóng sheet mà không
/// lưu thì trả về `null` (signal hủy).
class _ActivityEditorSheet extends StatefulWidget {
  const _ActivityEditorSheet({
    required this.dayIndex,
    required this.existingCount,
    this.initial,
    this.index,
  });
  final int dayIndex;
  final int existingCount;
  final Map<String, dynamic>? initial;
  final int? index;

  @override
  State<_ActivityEditorSheet> createState() => _ActivityEditorSheetState();
}

class _ActivityEditorSheetState extends State<_ActivityEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _destination;
  late final TextEditingController _address;
  late final TextEditingController _time;
  late final TextEditingController _duration;
  late final TextEditingController _cost;
  late final TextEditingController _note;
  late String _category;

  static const _categoryOptions = [
    {'value': 'tham quan', 'label': 'Tham quan', 'icon': Icons.explore_outlined, 'color': Color(0xFFA78BFA)},
    {'value': 'ăn uống', 'label': 'Ăn uống', 'icon': Icons.restaurant_outlined, 'color': Color(0xFFF59E0B)},
    {'value': 'khách sạn', 'label': 'Lưu trú', 'icon': Icons.hotel_outlined, 'color': Color(0xFFF472B6)},
    {'value': 'di chuyển', 'label': 'Di chuyển', 'icon': Icons.directions_bus_outlined, 'color': Color(0xFF0EA5E9)},
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initial ?? const <String, dynamic>{};
    _title = TextEditingController(text: '${init['activity'] ?? init['place'] ?? ''}');
    _destination = TextEditingController(text: '${init['destination'] ?? ''}');
    _address = TextEditingController(text: '${init['address'] ?? ''}');
    _time = TextEditingController(text: '${init['time'] ?? _suggestedTime()}');
    _duration = TextEditingController(text: '${init['duration'] ?? init['durationMinutes'] ?? '60'}');
    _cost = TextEditingController(text: '${init['estimatedCost'] ?? init['cost'] ?? 0}');
    _note = TextEditingController(text: '${init['note'] ?? ''}');
    _category = _normalizeCategory(init['category'] ?? init['type']);
  }

  String _normalizeCategory(dynamic raw) {
    final s = '$raw'.toLowerCase();
    if (s.contains('an') || s.contains('food')) return 'ăn uống';
    if (s.contains('hotel') || s.contains('khách')) return 'khách sạn';
    if (s.contains('transport') || s.contains('di chuy')) return 'di chuyển';
    return 'tham quan';
  }

  /// Gợi ý giờ tiếp theo dựa trên số activity đã có (mỗi cái cách nhau ~2h).
  String _suggestedTime() {
    final hour = 8 + (widget.existingCount * 2);
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  @override
  void dispose() {
    _title.dispose();
    _destination.dispose();
    _address.dispose();
    _time.dispose();
    _duration.dispose();
    _cost.dispose();
    _note.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_title.text.trim().isEmpty && _destination.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên hoạt động hoặc địa điểm.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final costNum = num.tryParse(_cost.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final result = <String, dynamic>{
      'time': _time.text.trim().isEmpty ? _suggestedTime() : _time.text.trim(),
      'activity': _title.text.trim().isEmpty
          ? _categoryOptions.firstWhere((c) => c['value'] == _category)['label']
          : _title.text.trim(),
      'destination': _destination.text.trim(),
      'address': _address.text.trim(),
      'duration': _duration.text.trim(),
      'category': _category,
      'estimatedCost': costNum,
      'note': _note.text.trim(),
    };
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initial == null ? 'Thêm hoạt động' : 'Sửa hoạt động',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ink),
            ),
            const SizedBox(height: 4),
            Text(
              'Ngày ${widget.dayIndex + 1}',
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 14),
            _CategoryChips(
              value: _category,
              options: _categoryOptions,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 14),
            _Field(controller: _title, label: 'Tên hoạt động', icon: Icons.local_activity_outlined),
            const SizedBox(height: 10),
            _Field(controller: _destination, label: 'Địa điểm', icon: Icons.place_outlined),
            const SizedBox(height: 10),
            _Field(controller: _address, label: 'Địa chỉ (tuỳ chọn)', icon: Icons.location_on_outlined),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _Field(controller: _time, label: 'Giờ (HH:mm)', icon: Icons.schedule_outlined, keyboardType: TextInputType.datetime)),
              const SizedBox(width: 10),
              Expanded(child: _Field(controller: _duration, label: 'Thời lượng (phút)', icon: Icons.timer_outlined, keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 10),
            _Field(controller: _cost, label: 'Chi phí ước tính (VNĐ)', icon: Icons.payments_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            _Field(controller: _note, label: 'Ghi chú (tuỳ chọn)', icon: Icons.note_outlined, maxLines: 2),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: _line, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Hủy',
                      style: TextStyle(fontWeight: FontWeight.w800, color: _muted)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _gradPrimary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Lưu hoạt động',
                        style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, size: 20, color: _primary),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String value;
  final List<Map<String, dynamic>> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final selected = opt['value'] == value;
        final color = opt['color'] as Color;
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: () => onChanged(opt['value'] as String),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? color : Colors.white,
                border: Border.all(
                  color: selected ? color : _line,
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: selected
                    ? [BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )]
                    : const [],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(opt['icon'] as IconData, size: 14, color: selected ? Colors.white : color),
                const SizedBox(width: 6),
                Text(
                  opt['label'] as String,
                  style: TextStyle(
                    color: selected ? Colors.white : _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}
