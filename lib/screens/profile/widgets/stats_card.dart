import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({super.key});

  static const _stats = [
    {'icon': Icons.luggage_outlined,   'value': '18',  'label': 'Trips'},
    {'icon': Icons.image_outlined,     'value': '532', 'label': 'Photos'},
    {'icon': Icons.video_library_outlined, 'value': '24', 'label': 'Videos'},
    {'icon': Icons.bookmark_outline,   'value': '12',  'label': 'Places'},
  ];

  static const _iconColors = [
    Color(0xFF3A7D5A),
    Color(0xFF7B68EE),
    Color(0xFFE8624A),
    Color(0xFFF5A623),
  ];

  static const _bgColors = [
    Color(0xFFE8F5E9),
    Color(0xFFEDE7F6),
    Color(0xFFFFEBEE),
    Color(0xFFFFF3E0),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Tăng margin để thoáng hơn
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Bo góc mềm mại hơn
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_stats.length, (i) => _StatItem(
          icon: _stats[i]['icon'] as IconData,
          value: _stats[i]['value'] as String,
          label: _stats[i]['label'] as String,
          iconColor: _iconColors[i],
          bgColor: _bgColors[i],
        )),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color bgColor;

  const _StatItem({required this.icon, required this.value, required this.label, required this.iconColor, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF888888))),
      ],
    );
  }
}
