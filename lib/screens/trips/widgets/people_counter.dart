import 'package:flutter/material.dart';

/// Bộ điều khiển "Số lượng người": nút trừ — số hiện tại — nút cộng.
class PeopleCounter extends StatelessWidget {
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const PeopleCounter({
    super.key,
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundIconButton(icon: Icons.remove, onTap: onDecrement),
        Text(
          '$count',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        _RoundIconButton(icon: Icons.add, onTap: onIncrement),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 20, color: Colors.grey.shade700),
      ),
    );
  }
}