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
    final total = cost['total'] ?? 0;
    final usage = userBudget != null && userBudget! > 0
        ? (total / userBudget!).clamp(0, 999).toDouble()
        : null;
    final remaining = usage == null ? null : (1 - usage).clamp(0, 1).toDouble();
    final rows = [
      _CostData(Icons.directions_bus_outlined, 'Di chuyển', cost['transport'] ?? 0, const Color(0xFF38BDF8)),
      _CostData(Icons.hotel_outlined, 'Lưu trú', cost['accommodation'] ?? 0, const Color(0xFFF472B6)),
      _CostData(Icons.restaurant_outlined, 'Ăn uống', cost['food'] ?? 0, const Color(0xFF4ADE80)),
      _CostData(Icons.local_activity_outlined, 'Vé & hoạt động', cost['activities'] ?? 0, const Color(0xFFA78BFA)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _TripItineraryResultScreenState._line),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                'Ngân sách dự kiến',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (userBudget == null || userBudget! <= 0) ...[
            _BudgetWarning(onSetupBudget: onSetupBudget),
            const SizedBox(height: 16),
          ],
          _BudgetSummaryGrid(
            total: total,
            userBudget: userBudget,
            usage: usage,
            remaining: remaining,
          ),
          if (usage != null) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: usage.clamp(0, 1),
                minHeight: 12,
                backgroundColor: const Color(0xFFF1F5F9),
                color: usage > 1 ? Colors.redAccent : const Color(0xFF10B981),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text('Phân bổ ngân sách', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 16),
          if (total > 0)
            SizedBox(
              height: 200,
              child: _BudgetDonutChart(rows: rows, total: total),
            ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn()
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Chưa có chi phí', style: TextStyle(color: Colors.grey)),
              ),
            ),
          const SizedBox(height: 20),
          _AiBudgetAnalysis(cost: cost).animate().slideY(begin: 0.2, end: 0, delay: 300.ms).fadeIn(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: onOptimizeBudget,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Tối ưu ngân sách', style: TextStyle(fontWeight: FontWeight.w800)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ).animate().slideY(begin: 0.2, end: 0, delay: 400.ms).fadeIn(),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}

class _BudgetWarning extends StatelessWidget {
  const _BudgetWarning({required this.onSetupBudget});

  final VoidCallback onSetupBudget;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEF3C7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Chưa thiết lập ngân sách',
              style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFD97706), fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onSetupBudget, 
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB45309),
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: const Text('Thiết lập'),
          ),
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
    return Row(
      children: [
        Expanded(
          child: _BudgetStat(
            label: 'Tổng chi phí', 
            value: _moneyOrStatus(total, empty: '--'),
            valueColor: _TripItineraryResultScreenState._ink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _BudgetStat(
            label: 'Ngân sách', 
            value: _budgetLabel(userBudget),
            valueColor: const Color(0xFF0EA5E9),
          ),
        ),
      ],
    );
  }
}

class _BudgetStat extends StatelessWidget {
  const _BudgetStat({required this.label, required this.value, required this.valueColor});

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _TripItineraryResultScreenState._muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetDonutChart extends StatefulWidget {
  const _BudgetDonutChart({required this.rows, required this.total});

  final List<_CostData> rows;
  final num total;

  @override
  State<_BudgetDonutChart> createState() => _BudgetDonutChartState();
}

class _BudgetDonutChartState extends State<_BudgetDonutChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 45,
              sections: widget.rows.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                final isTouched = i == touchedIndex;
                final value = row.value > 0 ? (row.value / widget.total) * 100 : 0.0;
                
                return PieChartSectionData(
                  color: row.color,
                  value: value,
                  title: isTouched ? '${value.toStringAsFixed(0)}%' : '',
                  radius: isTouched ? 45.0 : 35.0,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.rows.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              final isTouched = i == touchedIndex;
              final value = row.value > 0 ? (row.value / widget.total) * 100 : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isTouched ? 16 : 12,
                      height: isTouched ? 16 : 12,
                      decoration: BoxDecoration(
                        color: row.color,
                        shape: BoxShape.circle,
                        boxShadow: isTouched ? [BoxShadow(color: row.color.withValues(alpha: 0.4), blurRadius: 8)] : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        row.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isTouched ? FontWeight.w900 : FontWeight.w600,
                          color: _TripItineraryResultScreenState._ink,
                        ),
                      ),
                    ),
                    Text(
                      '${value.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isTouched ? FontWeight.w900 : FontWeight.bold,
                        color: isTouched ? row.color : _TripItineraryResultScreenState._muted,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF86EFAC).withValues(alpha: 0.4)),
        boxShadow: const [BoxShadow(color: Color(0x0522C55E), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, size: 18, color: Color(0xFF16A34A)),
              SizedBox(width: 8),
              Text('Phân tích AI', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF15803D))),
            ],
          ),
          const SizedBox(height: 12),
          ...notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 5, color: Color(0xFF22C55E)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 13,
                        height: 1.4,
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
  const _CostData(this.icon, this.label, this.value, this.color);

  final IconData icon;
  final String label;
  final num value;
  final Color color;
}
