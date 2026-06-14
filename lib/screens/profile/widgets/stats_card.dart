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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_stats.length, (i) => _StatItem(
          icon: _stats[i]['icon'] as IconData,
          value: _stats[i]['value'] as String,
          label: _stats[i]['label'] as String,
          iconColor: _iconColors[i],
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

  const _StatItem({required this.icon, required this.value, required this.label, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 26, color: iconColor),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
      ],
    );
  }
}