// ignore_for_file: use_string_in_part_of_directives

part of trip_route_analysis_screen;

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.analysis,
    required this.budgetTotal,
    required this.peopleCount,
  });

  final TripRouteAnalysis analysis;
  final double budgetTotal;
  final int peopleCount;

  @override
  Widget build(BuildContext context) {
    final totalTransportCost = analysis.estimatedRouteCostVnd * peopleCount;
    final budgetUsage = budgetTotal <= 0 ? 0.0 : totalTransportCost / budgetTotal * 100;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng quan hành trình', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _InfoRow(label: 'Tổng khoảng cách', value: '${analysis.totalDistanceKm.toStringAsFixed(0)} km'),
          _InfoRow(label: 'Tổng thời gian di chuyển', value: formatHours(analysis.optimizedHours)),
          _InfoRow(label: 'Tổng số chặng', value: '${analysis.legs.length} chặng'),
          _InfoRow(label: 'Số lần chuyển phương tiện', value: '${analysis.transferCount} lần'),
          _InfoRow(
            label: 'Chi phí di chuyển khứ hồi',
            value: BudgetTier.formatCurrency(totalTransportCost),
          ),
          _InfoRow(label: 'Tổng ngân sách nhóm', value: BudgetTier.formatCurrency(budgetTotal)),
          _BudgetUsageRow(percent: budgetUsage),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: analysis.aiBadges.map((badge) => _SummaryPill(text: badge)).toList(),
          ),
          if (analysis.importantNotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...analysis.importantNotes.map((note) => _SummaryNote(text: note)),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FBF8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCEEE5)),
            ),
            child: Text(
              analysis.aiRecommendation,
              style: const TextStyle(
                color: Color(0xFF38443C),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tone = _BadgeTone.fromText(text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tone.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BadgeTone {
  const _BadgeTone(this.background, this.foreground);

  final Color background;
  final Color foreground;

  static _BadgeTone fromText(String value) {
    if (value.contains('Phức tạp')) {
      return const _BadgeTone(Color(0xFFFFE4E6), Color(0xFFBE123C));
    }
    if (value.contains('Trung bình') || value.contains('Cân bằng')) {
      return const _BadgeTone(Color(0xFFFFF7CC), Color(0xFF9A6B00));
    }
    if (value.contains('Nhanh nhất')) {
      return const _BadgeTone(Color(0xFFE0F2FE), Color(0xFF0369A1));
    }
    if (value.contains('Tiết kiệm nhất')) {
      return const _BadgeTone(Color(0xFFEAF5F0), Color(0xFF0B7D4B));
    }
    return const _BadgeTone(Color(0xFFEAF5F0), Color(0xFF0B7D4B));
  }
}

class _SummaryNote extends StatelessWidget {
  const _SummaryNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 15, color: Color(0xFF647067)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF647067),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetUsageRow extends StatelessWidget {
  const _BudgetUsageRow({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final rounded = percent.round();
    final remaining = (100 - percent).clamp(0, 100).round();
    final tone = _toneForPercent(percent);
    final status = percent > 100
        ? 'Vượt ngân sách'
        : percent >= 80
            ? 'Gần chạm ngân sách'
            : 'Trong ngân sách';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Đã sử dụng',
                  style: TextStyle(color: Color(0xFF647067)),
                ),
              ),
              _BudgetPill(text: '$rounded% ngân sách', tone: tone),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ngân sách còn lại',
                  style: TextStyle(color: Color(0xFF647067)),
                ),
              ),
              _BudgetPill(
                text: percent > 100 ? '0% • $status' : '$remaining% • $status',
                tone: tone,
              ),
            ],
          ),
        ],
      ),
    );
  }

  _BadgeTone _toneForPercent(double value) {
    if (value > 100) {
      return const _BadgeTone(Color(0xFFFFE4E6), Color(0xFFBE123C));
    }
    if (value >= 80) {
      return const _BadgeTone(Color(0xFFFFF7CC), Color(0xFF9A6B00));
    }
    return const _BadgeTone(Color(0xFFEAF5F0), Color(0xFF0B7D4B));
  }
}

class _BudgetPill extends StatelessWidget {
  const _BudgetPill({required this.text, required this.tone});

  final String text;
  final _BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tone.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF647067)))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}


