import 'package:flutter/material.dart';
import 'package:assignment/core/theme/app_colors.dart';
import 'safe_network_image.dart';

class NetworkImageCard extends StatelessWidget {
  const NetworkImageCard({
    super.key,
    required this.imageUrl,
    this.height = 140,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(16)),
  });

  final String imageUrl;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SafeNetworkImage(
        url: imageUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        source: 'NetworkImageCard',
        loading: Container(
          height: height,
          color: AppColors.surface,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
        fallback: _NetworkImageFallback(height: height),
      ),
    );
  }
}

class _NetworkImageFallback extends StatelessWidget {
  const _NetworkImageFallback({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.primaryDark.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
    );
  }
}
