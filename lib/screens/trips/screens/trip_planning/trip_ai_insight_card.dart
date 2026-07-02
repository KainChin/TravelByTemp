import 'package:flutter/material.dart';

import 'trip_tokens.dart';
import 'trip_shared_widgets.dart';

class TripAiInsightCard extends StatelessWidget {
  const TripAiInsightCard({super.key, required this.onCreate});

  final VoidCallback onCreate;

  static const _insights = [
    _InsightData(
      Icons.trending_down_rounded,
      'Gia ve dang giam',
      'Thap hon khoang 15% so voi tuan truoc.',
      Color(0xFF22C55E),
    ),
    _InsightData(
      Icons.wb_sunny_rounded,
      'Thoi tiet dep',
      'Phu Quoc va Da Lat dang co cua so khoi hanh tot.',
      Color(0xFFF59E0B),
    ),
    _InsightData(
      Icons.local_fire_department_rounded,
      'Dang mua du lich',
      'Nhieu lich trinh 3 ngay duoc AI de xuat gan day.',
      Color(0xFFF97316),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: kGradDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331A1F36),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kTripPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF2ECC71),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Insight',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kTripPrimary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Live',
                  style: TextStyle(
                    color: Color(0xFF2ECC71),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_insights.length, (i) {
            final item = _insights[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i < _insights.length - 1 ? 10 : 0),
              child: _InsightRow(item: item),
            );
          }),
          const SizedBox(height: 18),
          TripPillButton(
            label: 'Tao lich trinh',
            icon: Icons.arrow_forward_rounded,
            gradient: kGradPrimary,
            onTap: onCreate,
          ),
        ],
      ),
    );
  }
}

class _InsightData {
  const _InsightData(this.icon, this.title, this.subtitle, this.color);

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.item});

  final _InsightData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, size: 17, color: item.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
