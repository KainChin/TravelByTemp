// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

/// Compact budget card — hiển thị tổng chi phí + breakdown 4 mục ngang.
/// Không dùng donut chart (chiếm không gian) hay button trùng (bottom bar đã có).
class BudgetSection extends StatelessWidget {
  const BudgetSection({
    super.key,
    required this.cost,
    required this.userBudget,
    required this.onOptimizeBudget,
    this.onSetupBudget,
  });

  final Map<String, num> cost;
  final num? userBudget;
  final VoidCallback onOptimizeBudget;
  final VoidCallback? onSetupBudget;

  @override
  Widget build(BuildContext context) {
    final total = cost['total'] ?? 0;
    final usage = userBudget != null && userBudget! > 0
        ? (total / userBudget!).clamp(0.0, 999.0)
        : null;

    final rows = [
      _CostItem(Icons.directions_bus_outlined, 'Di chuyển', cost['transport'] ?? 0, const Color(0xFF38BDF8)),
      _CostItem(Icons.hotel_outlined, 'Lưu trú', cost['accommodation'] ?? 0, const Color(0xFFF472B6)),
      _CostItem(Icons.restaurant_outlined, 'Ăn uống', cost['food'] ?? 0, const Color(0xFF4ADE80)),
      _CostItem(Icons.local_activity_outlined, 'Hoạt động', cost['activities'] ?? 0, const Color(0xFFA78BFA)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _TripItineraryResultScreenState._line),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF2E7D32), size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Chi phí dự kiến',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                _moneyOrStatus(total, empty: '--'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF008F6A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4-item compact breakdown
          Row(
            children: rows.asMap().entries.map((e) {
              final i = e.key;
              final row = e.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < rows.length - 1 ? 8 : 0),
                  child: _CostTile(
                    icon: row.icon,
                    label: row.label,
                    value: row.value > 0 ? _moneyOrStatus(row.value) : '—',
                    color: row.color,
                    emptyHint: row.value <= 0 ? _emptyHint(row.label) : null,
                  ),
                ),
              );
            }).toList(),
          ),

          // Budget progress bar (only if user set budget)
          if (userBudget != null && userBudget! > 0 && usage != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: usage.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: const Color(0xFFF1F5F9),
                color: usage > 1 ? Colors.redAccent : const Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              // remaining = userBudget - total (đã chi), KHÔNG phải userBudget gốc.
              // Cùng 1 giá trị này được dùng cho cả text + progress bar để đồng bộ.
              usage > 1
                  ? 'Vượt ngân sách ${((usage - 1) * 100).toStringAsFixed(0)}% (${_formatMoney(total - userBudget!)})'
                  : 'Còn ${_formatMoney(userBudget! - total)} / ${_formatMoney(userBudget!)} ngân sách',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: usage > 1 ? Colors.redAccent : const Color(0xFF10B981),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}

class _CostItem {
  const _CostItem(this.icon, this.label, this.value, this.color);
  final IconData icon;
  final String label;
  final num value;
  final Color color;
}

/// Hint ngắn khi 1 hạng mục không có dữ liệu — giúp user biết cần làm gì.
String _emptyHint(String label) {
  switch (label) {
    case 'Di chuyển':
      return 'Chưa chọn phương tiện ở bước trước';
    case 'Lưu trú':
      return 'Thêm khách sạn để ước tính';
    case 'Ăn uống':
      return 'Thêm quán ăn để ước tính';
    case 'Hoạt động':
      return 'Thêm hoạt động để ước tính';
    default:
      return 'Chưa có dữ liệu';
  }
}

class _CostTile extends StatelessWidget {
  const _CostTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.emptyHint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? emptyHint;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF15221D),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
    if (emptyHint == null) return tile;
    // Hint giúp user biết tại sao hiển thị "—" và cách bổ sung.
    return Tooltip(
      message: emptyHint!,
      waitDuration: const Duration(milliseconds: 250),
      child: tile,
    );
  }
}
