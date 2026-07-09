// ignore_for_file: use_string_in_part_of_directives

part of trip_route_analysis_screen;

class _SummaryCard extends StatefulWidget {
  const _SummaryCard({
    required this.analysis,
    required this.budgetTotal,
    required this.peopleCount,
  });

  final TripRouteAnalysis analysis;
  final double budgetTotal;
  final int peopleCount;

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  bool _isLoading = true;
  List<String> _aiBadges = [];
  String _aiRecommendation = '';

  @override
  void initState() {
    super.initState();
    _fetchGroqAnalysis();
  }

  @override
  void didUpdateWidget(covariant _SummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.analysis != oldWidget.analysis || widget.budgetTotal != oldWidget.budgetTotal) {
      _fetchGroqAnalysis();
    }
  }

  Future<void> _fetchGroqAnalysis() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final cost = widget.analysis.estimatedRouteCostVnd * widget.peopleCount;
    final dests = widget.analysis.destinations.map((d) => d.destination.name).join(', ');
    
    // Call Groq API via our new service
    final result = await GroqService.analyzeRouteBudget(
      totalDistanceKm: widget.analysis.totalDistanceKm,
      optimizedHours: widget.analysis.optimizedHours,
      estimatedCostVnd: cost,
      budgetVnd: widget.budgetTotal,
      transferCount: widget.analysis.transferCount,
      destinationsName: dests,
    );
    
    if (mounted) {
      setState(() {
        _aiBadges = List<String>.from(result['aiBadges'] ?? []);
        _aiRecommendation = result['aiRecommendation'] ?? '';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalTransportCost = widget.analysis.estimatedRouteCostVnd * widget.peopleCount;
    final budgetUsage = widget.budgetTotal <= 0 ? 0.0 : totalTransportCost / widget.budgetTotal * 100;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng quan hành trình', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _InfoRow(label: 'Tổng khoảng cách', value: '${widget.analysis.totalDistanceKm.toStringAsFixed(0)} km'),
          _InfoRow(label: 'Tổng thời gian di chuyển', value: formatHours(widget.analysis.optimizedHours)),
          _InfoRow(label: 'Tổng số chặng', value: '${widget.analysis.legs.length} chặng'),
          _InfoRow(label: 'Số lần chuyển phương tiện', value: '${widget.analysis.transferCount} lần'),
          _InfoRow(
            label: 'Chi phí di chuyển khứ hồi',
            value: BudgetTier.formatCurrency(totalTransportCost),
          ),
          _InfoRow(label: 'Tổng ngân sách nhóm', value: BudgetTier.formatCurrency(widget.budgetTotal)),
          _BudgetUsageRow(percent: budgetUsage),
          const SizedBox(height: 10),
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0FA958))
                )
              ),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _aiBadges.map((badge) => _SummaryPill(text: badge)).toList(),
            ),
            if (widget.analysis.importantNotes.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...widget.analysis.importantNotes.map((note) => _SummaryNote(text: note)),
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
                _aiRecommendation,
                style: const TextStyle(
                  color: Color(0xFF38443C),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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


