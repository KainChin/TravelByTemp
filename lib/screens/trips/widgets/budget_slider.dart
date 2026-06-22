import 'package:flutter/material.dart';

import '../models/budget_tier.dart';

/// Thanh trượt ngân sách mỗi người, chỉ cho phép dừng tại các nấc cố định
/// trong [BudgetTier.tiers] (500k, 700k, 1tr, 2tr, 5tr, 10tr+).
class BudgetSlider extends StatelessWidget {
  final int tierIndex;
  final ValueChanged<int> onChanged;

  const BudgetSlider({
    super.key,
    required this.tierIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final maxIndex = BudgetTier.tiers.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF0FA958),
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: const Color(0xFF0FA958),
            overlayColor: const Color(0x220FA958),
            trackHeight: 4,
          ),
          child: Slider(
            value: tierIndex.toDouble(),
            min: 0,
            max: maxIndex.toDouble(),
            divisions: maxIndex,
            label: BudgetTier.tiers[tierIndex].label,
            onChanged: (value) => onChanged(value.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                BudgetTier.tiers.first.label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              Text(
                BudgetTier.tiers.last.label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}