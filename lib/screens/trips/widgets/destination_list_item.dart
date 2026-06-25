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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8E4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D005B44),
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
                        'Chặng $order',
                        style: const TextStyle(
                          color: Color(0xFF008F6A),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.fromLabel} -> ${item.destination.name}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF15221D),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitleLabel,
                        style: const TextStyle(
                          color: Color(0xFF6E7A74),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    tooltip: 'Xóa điểm đến',
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: const Color(0xFF8A9690),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 14),
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
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  dateError!,
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
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
    final hasValue = value != null;
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7F4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue ? const Color(0xFFB7DED0) : const Color(0xFFE2E8E4),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: Color(0xFF008F6A),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6E7A74),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasValue ? _format(value!) : 'Chọn ngày',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: hasValue ? const Color(0xFF15221D) : const Color(0xFF9AA6A0),
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
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE0F4E9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$order',
        style: const TextStyle(
          color: Color(0xFF006B52),
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }
}
