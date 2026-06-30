import 'package:flutter/material.dart';

import '../models/budget_tier.dart';

class BudgetSlider extends StatefulWidget {
  const BudgetSlider({
    super.key,
    required this.amount,
    required this.onChanged,
  });

  final double amount;
  final ValueChanged<double> onChanged;

  @override
  State<BudgetSlider> createState() => _BudgetSliderState();
}

class _BudgetSliderState extends State<BudgetSlider> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: BudgetTier.formatCurrency(widget.amount),
    );
  }

  @override
  void didUpdateWidget(covariant BudgetSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      final formatted = BudgetTier.formatCurrency(widget.amount);
      if (_controller.text != formatted) _controller.text = formatted;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commitInput() {
    widget.onChanged(BudgetTier.parseCurrency(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _commitInput(),
            onEditingComplete: _commitInput,
            decoration: InputDecoration(
              labelText: 'Tổng ngân sách chuyến đi',
              prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF008F6A)),
              suffixText: 'VND',
              filled: true,
              fillColor: const Color(0xFFF5F7F4),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF008F6A),
              inactiveTrackColor: const Color(0xFFE2E8E4),
              thumbColor: const Color(0xFF008F6A),
              overlayColor: const Color(0x22008F6A),
              trackHeight: 5,
            ),
            child: Slider(
              value: widget.amount
                  .clamp(BudgetTier.minBudget, BudgetTier.maxBudget)
                  .toDouble(),
              min: BudgetTier.minBudget,
              max: BudgetTier.maxBudget,
              divisions: 199,
              label: BudgetTier.formatCurrency(widget.amount),
              onChanged: widget.onChanged,
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BudgetTier.quickChoices.map((choice) {
              final selected = widget.amount.round() == choice.value.round();
              return ChoiceChip(
                label: Text(choice.label),
                selected: selected,
                showCheckmark: false,
                selectedColor: const Color(0xFFE0F4E9),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? const Color(0xFF006B52) : const Color(0xFF6E7A74),
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: selected ? const Color(0xFF008F6A) : const Color(0xFFE2E8E4),
                ),
                onSelected: (_) => widget.onChanged(choice.value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
