import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class HeroBanner extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onStartPressed;

  const HeroBanner({
    super.key,
    required this.imageUrl,
    required this.onStartPressed,
  });

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: widget.imageUrl,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 300),
              placeholder: (context, url) => Container(color: const Color(0xFFFAFAFA)),
              errorWidget: (context, url, error) => Container(color: const Color(0xFFFAFAFA)),
            ),
          ),
          
          // Dark Overlay 35%
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),

          // Content
          Positioned(
            left: 40,
            bottom: 40,
            right: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Khám phá chuyến đi tiếp theo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 8),
                Text(
                  'AI sẽ giúp bạn xây dựng hành trình tối ưu chỉ trong vài giây.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 32),
                
                // Premium Button
                MouseRegion(
                  onEnter: (_) => setState(() => _isHovering = true),
                  onExit: (_) => setState(() => _isHovering = false),
                  child: GestureDetector(
                    onTap: widget.onStartPressed,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutQuart,
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF111111), // Very dark premium grey/black
                            Color(0xFF333333),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(_isHovering ? 0.3 : 0.15),
                            blurRadius: _isHovering ? 20 : 12,
                            offset: Offset(0, _isHovering ? 8 : 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Bắt đầu ngay',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedSlide(
                            offset: _isHovering ? const Offset(0.2, 0) : Offset.zero,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutQuart,
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2500.ms, delay: 1000.ms, color: Colors.white24) // Sparkle effect
                  .scaleXY(
                    begin: 1.0, 
                    end: _isHovering ? 1.02 : 1.0, 
                    duration: 200.ms, 
                    curve: Curves.easeOutQuart
                  ),
                ).animate().fadeIn(delay: 200.ms).scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOutQuart),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
