import 'package:flutter/material.dart';

class SafeNetworkImage extends StatelessWidget {
  const SafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
    this.loading,
    this.source = 'network image',
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;
  final Widget? loading;
  final String source;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = url?.trim() ?? '';
    final uri = Uri.tryParse(trimmedUrl);
    final isValidHttpUrl = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;

    if (!isValidHttpUrl) {
      debugPrint('[ImageDecode] Invalid image URL from $source: "$url"');
      return _fallback();
    }

    return Image.network(
      trimmedUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return loading ?? _fallback(icon: Icons.image_outlined);
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[ImageDecode] Failed to load image from $source.');
        debugPrint('[ImageDecode] URL: $trimmedUrl');
        if (error is NetworkImageLoadException) {
          debugPrint('[ImageDecode] HTTP Status Code: ${error.statusCode}');
        }
        debugPrint('[ImageDecode] Error: $error');
        return _fallback();
      },
    );
  }

  Widget _fallback({IconData icon = Icons.broken_image_outlined}) {
    if (fallback != null) return fallback!;
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: Icon(icon, color: const Color(0xFF9CA3AF)),
    );
  }
}
