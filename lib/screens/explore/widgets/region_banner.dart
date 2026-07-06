import 'dart:async';
import 'package:flutter/material.dart';
import 'package:assignment/core/widgets/safe_network_image.dart';
import 'package:assignment/services/api_client.dart';
import '../models/region_model.dart';

class RegionBanner extends StatefulWidget {
  final RegionModel region;
  final List<BannerItem> banners;
  final VoidCallback? onExplore;

  const RegionBanner({
    super.key,
    required this.region,
    required this.banners,
    this.onExplore,
  });

  @override
  State<RegionBanner> createState() => _RegionBannerState();
}

class _RegionBannerState extends State<RegionBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant RegionBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _timer?.cancel();
      _startTimer();
    }
  }

  void _startTimer() {
    if (widget.banners.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (!mounted || !_pageController.hasClients) return;
        final next = (_currentPage + 1) % widget.banners.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return _buildSingleBanner(
        title: widget.region.name,
        subtitle: widget.region.englishName,
        description: widget.region.description,
        imageUrl: widget.region.bannerImage,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemCount: widget.banners.length,
              itemBuilder: (context, index) {
                final banner = widget.banners[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    SafeNetworkImage(
                      url: banner.imageUrl,
                      fit: BoxFit.cover,
                      fallback: Container(color: const Color(0xFF16A34A)),
                      source: 'banner image',
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [Colors.transparent, Color(0xCC000000)],
                        ),
                      ),
                    ),
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
                            banner.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          if (banner.linkUrl != null && banner.linkUrl!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              banner.linkUrl!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4ADE80),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 16),
                          _ExploreButton(onTap: widget.onExplore),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              bottom: 16,
              right: 20,
              child: _DotIndicators(
                count: widget.banners.length,
                activeIndex: _currentPage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleBanner({
    required String title,
    required String subtitle,
    required String description,
    required String imageUrl,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeNetworkImage(
              url: imageUrl,
              fit: BoxFit.cover,
              fallback: Container(color: const Color(0xFF16A34A)),
              source: 'region banner image',
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
            ),
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
                    title,
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
                        subtitle,
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
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xDDFFFFFF),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  _ExploreButton(onTap: widget.onExplore),
                ],
              ),
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
