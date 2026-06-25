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
      if (_controller.text != formatted) {
        _controller.text = formatted;
      }
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              labelText: 'Ngân sách mỗi người',
              prefixIcon: const Icon(Icons.payments_outlined),
              suffixText: 'VND',
              filled: true,
              fillColor: const Color(0xFFF7FAF8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF0FA958),
              inactiveTrackColor: const Color(0xFFE2E8E4),
              thumbColor: const Color(0xFF0FA958),
              overlayColor: const Color(0x220FA958),
              trackHeight: 5,
            ),
            child: Slider(
              value: widget.amount
                  .clamp(BudgetTier.minBudget, BudgetTier.maxBudget)
                  .toDouble(),
              min: BudgetTier.minBudget,
              max: BudgetTier.maxBudget,
              divisions: 39,
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
                selectedColor: const Color(0xFFE0F4E9),
                labelStyle: TextStyle(
                  color: selected ? const Color(0xFF0B7D4B) : const Color(0xFF647067),
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(
                  color: selected ? const Color(0xFF0FA958) : const Color(0xFFE2E8E4),
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
