import 'package:flutter/material.dart';

import '../models/destination.dart';

class DestinationListItem extends StatelessWidget {
  const DestinationListItem({
    super.key,
    required this.order,
    required this.item,
    this.onRemove,
    this.onStartDatePicked,
    this.onEndDatePicked,
    this.firstStartDate,
    this.lastEndDate,
    this.dateError,
  });

  final int order;
  final SelectedDestination item;
  final VoidCallback? onRemove;
  final ValueChanged<DateTime>? onStartDatePicked;
  final ValueChanged<DateTime>? onEndDatePicked;
  final DateTime? firstStartDate;
  final DateTime? lastEndDate;
  final String? dateError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8E4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0B7D4B),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _OrderBadge(order: order),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chặng $order: ${item.fromLabel} → ${item.destination.name}',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitleLabel,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: Colors.grey.shade500,
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SmallDateButton(
                    label: 'Ngày bắt đầu',
                    value: item.startDate,
                    firstDate: firstStartDate,
                    lastDate: lastEndDate,
                    onPicked: onStartDatePicked,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SmallDateButton(
                    label: 'Ngày kết thúc',
                    value: item.endDate,
                    firstDate: item.startDate ?? firstStartDate,
                    lastDate: lastEndDate,
                    onPicked: onEndDatePicked,
                  ),
                ),
              ],
            ),
            if (dateError != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  dateError!,
                  style: const TextStyle(color: Color(0xFFB42318), fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SmallDateButton extends StatelessWidget {
  const _SmallDateButton({
    required this.label,
    required this.value,
    required this.onPicked,
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime>? onPicked;
  final DateTime? firstDate;
  final DateTime? lastDate;

  Future<void> _openPicker(BuildContext context) async {
    if (onPicked == null) return;
    final now = DateTime.now();
    final minDate = firstDate ?? now;
    final maxDate = lastDate ?? DateTime(now.year + 2);
    var initialDate = value ?? minDate;
    if (initialDate.isBefore(minDate)) initialDate = minDate;
    if (initialDate.isAfter(maxDate)) initialDate = maxDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: maxDate,
    );
    if (picked != null) onPicked!(picked);
  }

  String _format(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDCE8E1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF0FA958)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF647067))),
                  const SizedBox(height: 2),
                  Text(
                    value == null ? 'Chọn ngày' : _format(value!),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: value == null ? Colors.grey.shade500 : const Color(0xFF1B1F1C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderBadge extends StatelessWidget {
  const _OrderBadge({required this.order});

  final int order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF0FA958),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$order',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
