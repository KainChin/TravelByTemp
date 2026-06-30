// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

class BudgetSection extends StatelessWidget {
  const BudgetSection({
    super.key,
    required this.cost,
    required this.userBudget,
    required this.onOptimizeBudget,
    required this.onSetupBudget,
  });

  final Map<String, num> cost;
  final num? userBudget;
  final VoidCallback onOptimizeBudget;
  final VoidCallback onSetupBudget;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = cost['total'] ?? 0;
    final usage = userBudget != null && userBudget! > 0
        ? (total / userBudget!).clamp(0, 999).toDouble()
        : null;
    final remaining = usage == null ? null : (1 - usage).clamp(0, 1).toDouble();
    final rows = [
      _CostData(Icons.directions_bus_outlined, 'Di chuyển', cost['transport'] ?? 0),
      _CostData(Icons.hotel_outlined, 'Lưu trú', cost['accommodation'] ?? 0),
      _CostData(Icons.restaurant_outlined, 'Ăn uống', cost['food'] ?? 0),
      _CostData(Icons.local_activity_outlined, 'Vé & hoạt động', cost['activities'] ?? 0),
    ];

    return _Surface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ngân sách dự kiến',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          if (userBudget == null || userBudget! <= 0) ...[
            _BudgetWarning(onSetupBudget: onSetupBudget),
            const SizedBox(height: 14),
          ],
          _BudgetSummaryGrid(
            total: total,
            userBudget: userBudget,
            usage: usage,
            remaining: remaining,
          ),
          if (usage != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: usage.clamp(0, 1),
                minHeight: 10,
                backgroundColor: const Color(0xFFE8EFEA),
                color: usage > 1 ? Colors.redAccent : scheme.primary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Phân bổ ngân sách', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...rows.map((row) => _AllocationBar(row: row, total: total)),
          const SizedBox(height: 12),
          _AiBudgetAnalysis(cost: cost),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onOptimizeBudget,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Tối ưu ngân sách'),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetWarning extends StatelessWidget {
  const _BudgetWarning({required this.onSetupBudget});

  final VoidCallback onSetupBudget;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7CC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF9A6B00)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Chưa thiết lập ngân sách',
              style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF9A6B00)),
            ),
          ),
          TextButton(onPressed: onSetupBudget, child: const Text('Thiết lập')),
        ],
      ),
    );
  }
}

class _BudgetSummaryGrid extends StatelessWidget {
  const _BudgetSummaryGrid({
    required this.total,
    required this.userBudget,
    required this.usage,
    required this.remaining,
  });

  final num total;
  final num? userBudget;
  final double? usage;
  final double? remaining;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _BudgetStat(label: 'Tổng chi phí', value: _moneyOrStatus(total, empty: 'Đang tính...')),
        _BudgetStat(label: 'Ngân sách', value: _budgetLabel(userBudget)),
        _BudgetStat(label: 'Đã sử dụng', value: usage == null ? 'Chưa chọn' : '${(usage! * 100).round()}%'),
        _BudgetStat(label: 'Còn lại', value: remaining == null ? 'Chưa chọn' : '${(remaining! * 100).round()}%'),
      ],
    );
  }
}

class _BudgetStat extends StatelessWidget {
  const _BudgetStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _TripItineraryResultScreenState._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _TripItineraryResultScreenState._muted)),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: _TripItineraryResultScreenState._ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllocationBar extends StatelessWidget {
  const _AllocationBar({required this.row, required this.total});

  final _CostData row;
  final num total;

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (row.value / total).clamp(0, 1).toDouble() : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Icon(row.icon, size: 16, color: _TripItineraryResultScreenState._primary),
              const SizedBox(width: 8),
              Expanded(child: Text(row.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
              Text('${(ratio * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: const Color(0xFFE8EFEA),
              color: _TripItineraryResultScreenState._primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiBudgetAnalysis extends StatelessWidget {
  const _AiBudgetAnalysis({required this.cost});

  final Map<String, num> cost;

  @override
  Widget build(BuildContext context) {
    final notes = _budgetAnalysisNotes(cost).take(3);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _TripItineraryResultScreenState._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.smart_toy_outlined, size: 17, color: _TripItineraryResultScreenState._primary),
              SizedBox(width: 7),
              Text('AI phân tích ngân sách', style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          ...notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: _TripItineraryResultScreenState._muted)),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(
                        color: _TripItineraryResultScreenState._muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CostData {
  const _CostData(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final num value;
}
