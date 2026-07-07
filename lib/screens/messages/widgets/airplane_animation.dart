import 'dart:math';
import 'package:flutter/material.dart';

class AirplaneAnimation extends StatelessWidget {
  const AirplaneAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Classic Travel Jet (Blue, size 32, bottom-left to top-right diagonal)
        _SinglePlaneAnimation(
          icon: Icons.local_airport_rounded,
          color: const Color(0xFF1976D2), // Blue
          size: 32,
          duration: const Duration(seconds: 8),
          delay: Duration.zero,
          getPath: (progress, width, height) {
            final dx = -50 + (width + 100) * progress;
            final dy = (height * 0.85) - (height * 0.7 * progress);
            final angle = -pi / 6;
            return _PlanePosition(dx, dy, angle);
          },
        ),
        // 2. Paper Airplane (Slate Grey, size 26, gentle sine wave left-to-right)
        _SinglePlaneAnimation(
          icon: Icons.send_rounded,
          color: const Color(0xFF546E7A),
          size: 26,
          duration: const Duration(seconds: 12),
          delay: const Duration(seconds: 2),
          getPath: (progress, width, height) {
            final dx = -50 + (width + 100) * progress;
            final dy = (height * 0.4) + sin(progress * pi * 4) * 60;
            final angle = cos(progress * pi * 4) * 0.3;
            return _PlanePosition(dx, dy, angle);
          },
        ),
        // 3. Tiny Drone (Amber/Orange, size 24, orbital circular hover top-right)
        _SinglePlaneAnimation(
          icon: Icons.blur_on_rounded, // Looks like a drone prop
          color: const Color(0xFFFFB300), // Amber
          size: 24,
          duration: const Duration(seconds: 15),
          delay: const Duration(seconds: 4),
          getPath: (progress, width, height) {
            final centerX = width * 0.75;
            final centerY = height * 0.25;
            final radius = min(width, height) * 0.12;
            final dx = centerX + cos(progress * pi * 2) * radius;
            final dy = centerY + sin(progress * pi * 2) * radius;
            // Face tangential to circle
            final angle = progress * pi * 2 + pi / 2;
            return _PlanePosition(dx, dy, angle);
          },
        ),
        // 4. Supersonic Concorde (Red/Rose, size 28, fast right-to-left horizontal)
        _SinglePlaneAnimation(
          icon: Icons.flight_takeoff_rounded,
          color: const Color(0xFFE91E63), // Pink/Red
          size: 28,
          duration: const Duration(seconds: 6),
          delay: const Duration(seconds: 1),
          getPath: (progress, width, height) {
            final dx = (width + 100) - (width + 200) * progress;
            final dy = height * 0.6;
            final angle = pi; // Facing left
            return _PlanePosition(dx, dy, angle);
          },
        ),
        // 5. Hot Air Balloon (Green, size 30, slow float vertical sinus wave)
        _SinglePlaneAnimation(
          icon: Icons.brightness_7_rounded, // Looks like a hot air balloon silhouette
          color: const Color(0xFF4CAF50), // Green
          size: 30,
          duration: const Duration(seconds: 22),
          delay: const Duration(seconds: 3),
          getPath: (progress, width, height) {
            final dx = (width * 0.15) + sin(progress * pi * 3) * 40;
            final dy = (height + 50) - (height + 100) * progress;
            final angle = 0.0;
            return _PlanePosition(dx, dy, angle);
          },
        ),
        // 6. Helicopter (Teal, size 26, diagonal bottom-right to top-left)
        _SinglePlaneAnimation(
          icon: Icons.toys_rounded, // Propeller-like helicopter icon
          color: const Color(0xFF00ACC1), // Teal
          size: 26,
          duration: const Duration(seconds: 10),
          delay: const Duration(seconds: 5),
          getPath: (progress, width, height) {
            final dx = (width + 50) - (width + 100) * progress;
            final dy = (height * 0.8) - (height * 0.6 * progress);
            final angle = -pi * 5 / 6;
            return _PlanePosition(dx, dy, angle);
          },
        ),
      ],
    );
  }
}

class _PlanePosition {
  final double x;
  final double y;
  final double angle;
  _PlanePosition(this.x, this.y, this.angle);
}

class _SinglePlaneAnimation extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final Duration duration;
  final Duration delay;
  final _PlanePosition Function(double progress, double width, double height) getPath;

  const _SinglePlaneAnimation({
    required this.icon,
    required this.color,
    required this.size,
    required this.duration,
    required this.delay,
    required this.getPath,
  });

  @override
  State<_SinglePlaneAnimation> createState() => _SinglePlaneAnimationState();
}

class _SinglePlaneAnimationState extends State<_SinglePlaneAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isDelaying = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (widget.delay == Duration.zero) {
      _isDelaying = false;
      _controller.repeat();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          setState(() => _isDelaying = false);
          _controller.repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDelaying) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final pos = widget.getPath(_animation.value, screenWidth, screenHeight);

        return Positioned(
          left: pos.x,
          top: pos.y,
          child: Transform.rotate(
            angle: pos.angle,
            child: Opacity(
              opacity: 0.65, // Increased opacity for high visibility
              child: Icon(
                widget.icon,
                color: widget.color,
                size: widget.size,
              ),
            ),
          ),
        );
      },
    );
  }
}
