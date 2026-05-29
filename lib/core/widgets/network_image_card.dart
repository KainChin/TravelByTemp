import 'package:flutter/material.dart';
import 'package:assignment/core/theme/app_colors.dart';

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
      child: Image.network(
        imageUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            height: height,
            color: AppColors.surface,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.3),
                AppColors.primaryDark.withValues(alpha: 0.5),
              ],
            ),
          ),
          child: const Icon(Icons.image, color: Colors.white54, size: 48),
        ),
      ),
    );
  }
}
