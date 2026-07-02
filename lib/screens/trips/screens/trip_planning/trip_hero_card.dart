import 'package:assignment/core/widgets/safe_network_image.dart';
import 'package:flutter/material.dart';

import 'trip_tokens.dart';
import 'trip_shared_widgets.dart';

class TripHeroCard extends StatelessWidget {
  const TripHeroCard({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCreate,
      child: Container(
        height: 180,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: kTripPrimary.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 12)),
          ],
        ),
        child: Stack(fit: StackFit.expand, children: [
          // ── Background image
          SafeNetworkImage(
            url:
                'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1100&q=80',
            fit: BoxFit.cover,
            source: 'trip hero',
            fallback: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2D9F75), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // ── Gradient overlay — strong for readability
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xEE0F172A),
                  Color(0x880F172A),
                  Color(0x220F172A),
                ],
                stops: [0.0, 0.55, 1.0],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          // ── Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TripGlassTag(
                    icon: Icons.auto_awesome, label: 'AI Travel Planner'),
                const Spacer(),
                const Text(
                  'Khám phá & lên kế hoạch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Color(0x88000000), blurRadius: 16)
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'AI tự động phân tích tuyến đường và tạo lịch trình theo ngân sách.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
                      fontSize: 13),
                ),
                const SizedBox(height: 14),
                TripPillButton(
                  label: 'Bắt đầu ngay',
                  icon: Icons.arrow_forward_rounded,
                  gradient: kGradPrimary,
                  onTap: onCreate,
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
