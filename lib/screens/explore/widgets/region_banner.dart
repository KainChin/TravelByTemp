import 'package:flutter/material.dart';
import '../models/region_model.dart';

class RegionBanner extends StatelessWidget {
  final RegionModel region;
  final VoidCallback? onExplore;

  const RegionBanner({super.key, required this.region, this.onExplore});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.network(
              region.bannerImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF16A34A)),
            ),
            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
            ),
            // Content
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              top: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    region.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF4ADE80), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        region.englishName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4ADE80),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    region.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xDDFFFFFF),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  _ExploreButton(onTap: onExplore),
                ],
              ),
            ),
            // Dot indicators
            Positioned(
              bottom: 16,
              right: 20,
              child: _DotIndicators(count: 4, activeIndex: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _ExploreButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Khám phá ngay',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF111827)),
          ],
        ),
      ),
    );
  }
}

class _DotIndicators extends StatelessWidget {
  final int count;
  final int activeIndex;
  const _DotIndicators({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return Container(
          margin: const EdgeInsets.only(left: 6),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white38,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
