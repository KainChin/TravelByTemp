import 'package:flutter/material.dart';

class PeopleCounter extends StatelessWidget {
  const PeopleCounter({
    super.key,
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.group_outlined, color: Color(0xFF008F6A)),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Số người',
                style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF15221D)),
              ),
              SizedBox(height: 2),
              Text(
                'Áp dụng cho ngân sách / người',
                style: TextStyle(
                  color: Color(0xFF6E7A74),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _RoundIconButton(icon: Icons.remove_rounded, onTap: onDecrement),
        SizedBox(
          width: 44,
          child: Text(
            '$count',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xFF15221D),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _RoundIconButton(icon: Icons.add_rounded, onTap: onIncrement),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8E4)),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF15221D)),
      ),
    );
  }
}
