import 'package:assignment/core/widgets/safe_network_image.dart';
import 'package:flutter/material.dart';

import 'trip_tokens.dart';
import 'trip_shared_widgets.dart';

class TripInspirationCard extends StatelessWidget {
  const TripInspirationCard({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kTripLine),
        boxShadow: const [
          BoxShadow(color: Color(0x080F172A), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: tripIsDesktop(context) ? 180 : 150,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: SafeNetworkImage(
                    url: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=900&q=80',
                    fit: BoxFit.cover,
                    source: 'Phu Quoc',
                    fallback: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2D9F75), Color(0xFF0D9488)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: const Icon(Icons.beach_access_rounded, color: Colors.white, size: 40),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.58),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 14,
                  bottom: 14,
                  right: 14,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _OverlayChip(icon: Icons.auto_awesome, label: 'AI Score 94'),
                      _OverlayChip(icon: Icons.star_rounded, label: '4.8'),
                      _OverlayChip(icon: Icons.local_fire_department_rounded, label: 'Trending'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phu Quoc 3 ngay 2 dem',
                  style: TextStyle(color: kTripInk, fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bien, hai san va hoang hon voi lich trinh AI toi uu cho cap doi.',
                  style: TextStyle(
                    color: kTripMuted.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 7,
                  children: const [
                    _MetaChip(icon: Icons.visibility_rounded, label: '12k views', color: kTripTeal),
                    _MetaChip(icon: Icons.account_balance_wallet_outlined, label: '~3.5tr', color: kTripCoral),
                    _MetaChip(icon: Icons.savings_rounded, label: 'Save 15%', color: kTripPrimary),
                    _MetaChip(icon: Icons.beach_access_rounded, label: 'Best season', color: Color(0xFFEC4899)),
                  ],
                ),
                const SizedBox(height: 16),
                TripPillButton(
                  label: 'Kham pha ngay',
                  icon: Icons.explore_rounded,
                  gradient: kGradPrimary,
                  onTap: onCreate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: kTripPrimary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: kTripInk, fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
