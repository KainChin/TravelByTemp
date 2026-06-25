import 'package:flutter/material.dart';

/// Một ô bấm để mở [showDatePicker] và hiển thị ngày đã chọn (Ngày đi / Ngày về).
class DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;
  final DateTime? firstSelectableDate;
  final DateTime? lastSelectableDate;

  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onPicked,
    this.firstSelectableDate,
    this.lastSelectableDate,
  });

  Future<void> _openPicker(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = firstSelectableDate ?? now;
    final lastDate = lastSelectableDate ?? DateTime(now.year + 2);
    var initialDate = value ?? firstDate;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) onPicked(picked);
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _openPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  value != null ? _formatDate(value!) : 'dd/mm/yyyy',
                  style: TextStyle(
                    color: value != null ? Colors.black87 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
