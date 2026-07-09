import 'package:flutter/material.dart';
import 'package:assignment/core/widgets/safe_network_image.dart';
import '../models/destination_model.dart';

class DestinationCard extends StatefulWidget {
  final DestinationModel destination;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onTap;

  final double? width;

  const DestinationCard({
    super.key,
    required this.destination,
    this.onFavoriteTap,
    this.onTap,
    this.width = 170.0,
  });

  @override
  State<DestinationCard> createState() => _DestinationCardState();
}

class _DestinationCardState extends State<DestinationCard> {
  bool _isHovered = false;

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: widget.width,
          transform: _isHovered
              ? (Matrix4.identity()..scale(1.03))
              : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _CardImage(
                imageUrl: widget.destination.imageUrl,
                isFavorite: widget.destination.isFavorite,
                onFavoriteTap: widget.onFavoriteTap,
                isHovered: _isHovered,
                width: widget.width,
              ),
              const SizedBox(height: 10),
              Text(
                widget.destination.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                widget.destination.province,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              _RatingRow(rating: widget.destination.rating),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final String imageUrl;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final bool isHovered;
  final double? width;

  const _CardImage({
    required this.imageUrl,
    required this.isFavorite,
    this.onFavoriteTap,
    required this.isHovered,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isHovered ? 0.20 : 0.08),
            blurRadius: isHovered ? 20 : 10,
            offset: Offset(0, isHovered ? 10 : 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 1.0, // Perfect square aspect ratio
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeNetworkImage(
                url: imageUrl,
                fit: BoxFit.cover,
                source: 'destination card image',
              ),
              // Concentric ripple wave effect on hover
              _WaveEffect(isHovered: isHovered),
              // Bottom gradient to stand out text
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Floating Favorite Heart Icon with Elastic Pop Animation
              Positioned(
                top: 10,
                right: 10,
                child: _FavoriteButton(
                  isFavorite: isFavorite,
                  onTap: onFavoriteTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveEffect extends StatefulWidget {
  final bool isHovered;
  const _WaveEffect({required this.isHovered});

  @override
  State<_WaveEffect> createState() => _WaveEffectState();
}

class _WaveEffectState extends State<_WaveEffect> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.isHovered) {
      _controller!.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _WaveEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      );
    if (widget.isHovered && !oldWidget.isHovered) {
      _controller!.repeat();
    } else if (!widget.isHovered && oldWidget.isHovered) {
      _controller!.stop();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isHovered) return const SizedBox.shrink();

    // Safety check for hot reloads
    if (_controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      );
      _controller!.repeat();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _controller!,
          builder: (context, child) {
            final progress = _controller!.value;
            return Stack(
              children: List.generate(3, (index) {
                // Delay each circle wave progress to stagger the effect
                final waveProgress = (progress - (index * 0.33)) % 1.0;
                final scale = 0.15 + (waveProgress * 0.85); // dynamic expansion
                final opacity = (1.0 - waveProgress).clamp(0.0, 1.0); // fade out

                return Positioned.fill(
                  child: Center(
                    child: Container(
                      width: size * scale,
                      height: size * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1976D2).withOpacity(opacity * 0.45),
                          width: 1.5,
                        ),
                        color: const Color(0xFF1976D2).withOpacity(opacity * 0.08),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback? onTap;

  const _FavoriteButton({
    required this.isFavorite,
    this.onTap,
  });

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 0.9)
            .chain(CurveTween(curve: Curves.elasticIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite && !oldWidget.isFavorite) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () {
          if (widget.onTap != null) {
            widget.onTap!();
            // Trigger animation on tap too if favoriting
            if (!widget.isFavorite) {
              _controller.forward(from: 0.0);
            }
          }
        },
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            widget.isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
            size: 18,
            color: widget.isFavorite ? Colors.redAccent : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  const _RatingRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}
