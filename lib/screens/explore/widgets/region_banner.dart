import 'dart:async';
import 'dart:ui';
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

class _RegionBannerState extends State<RegionBanner>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // Text entrance animations
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _startTimer();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant RegionBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _timer?.cancel();
      _startTimer();
    }
    // Re-trigger animations when region changes
    if (oldWidget.region.id != widget.region.id) {
      _animController.reset();
      _animController.forward();
    }
  }

  void _startTimer() {
    if (widget.banners.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
        if (!mounted || !_pageController.hasClients) return;
        final next = (_currentPage + 1) % widget.banners.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String _getRegionBadge(String regionName) {
    if (regionName.contains('Tây')) return 'Vùng đất sông nước';
    if (regionName.contains('Bắc')) return 'Vùng đất di sản';
    if (regionName.contains('Trung')) return 'Vùng đất di tích';
    if (regionName.contains('Nam')) return 'Vùng đất năng động';
    return 'Vùng đất du lịch';
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
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 280, // Premium enlarged height
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
                    // Dark linear overlay gradient
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black87,
                            Colors.black38,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // Animated text and elements
                    Positioned(
                      left: 28,
                      right: 28,
                      bottom: 28,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Glassmorphism Badge
                              ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    color: Colors.white.withOpacity(0.15),
                                    child: Text(
                                      _getRegionBadge(widget.region.name),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                banner.title,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.region.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.85),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _ExploreButton(onTap: widget.onExplore),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              bottom: 28,
              right: 28,
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
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 280,
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
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black87,
                    Colors.black26,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: 28,
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Glassmorphism Badge
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            color: Colors.white.withOpacity(0.15),
                            child: Text(
                              _getRegionBadge(title),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
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
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1976D2), // Premium Bright Blue Button
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1976D2).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Khám phá ngay',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
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
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(left: 6),
          width: isActive ? 24 : 6,
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
