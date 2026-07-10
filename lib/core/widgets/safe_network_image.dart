import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../utils/safe_image_data.dart';

class SafeNetworkImage extends StatefulWidget {
  const SafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
    this.loading,
    this.source = 'network image',
    this.cacheWidth,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;
  final Widget? loading;
  final String source;
  final int? cacheWidth;

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage> {
  Future<_NetworkImageDecision>? _decision;
  String? _validatedUrl;

  @override
  void initState() {
    super.initState();
    _prepareDecision();
  }

  @override
  void didUpdateWidget(covariant SafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.source != widget.source) {
      _prepareDecision();
    }
  }

  void _prepareDecision() {
    final trimmedUrl = widget.url?.trim() ?? '';
    _validatedUrl = trimmedUrl;
    _decision = _validateNetworkImageUrl(trimmedUrl);
  }

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = _validatedUrl ?? '';
    return FutureBuilder<_NetworkImageDecision>(
      future: _decision,
      builder: (context, snapshot) {
        final decision = snapshot.data;
        if (decision == null) {
          return widget.loading ?? _fallback(icon: Icons.image_outlined);
        }
        if (!decision.showImage) {
          return _fallback();
        }
        return _buildImage(trimmedUrl);
      },
    );
  }

  Future<_NetworkImageDecision> _validateNetworkImageUrl(String trimmedUrl) async {
    final uri = Uri.tryParse(trimmedUrl);
    final isValidHttpUrl = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    if (!isValidHttpUrl) {
      logImageDecodeIssueOnce(
        'invalid-url|${widget.source}|$trimmedUrl',
        () => debugPrint('[ImageDecode] Invalid image URL from ${widget.source}: "${widget.url}"'),
      );
      return const _NetworkImageDecision(showImage: false);
    }

    if (isKnownNonImageUrl(uri)) {
      logImageDecodeIssueOnce(
        'non-image-url|${widget.source}|$trimmedUrl',
        () => debugPrint('[ImageDecode] Skipped non-image URL from ${widget.source}: $trimmedUrl'),
      );
      return const _NetworkImageDecision(showImage: false);
    }

    if (hasSupportedImageUrlExtension(uri)) {
      return const _NetworkImageDecision(showImage: true);
    }

    try {
      final response = await http.head(uri).timeout(const Duration(seconds: 4));
      final contentType = response.headers['content-type'];
      if (response.statusCode >= 200 &&
          response.statusCode < 400 &&
          isSupportedImageContentType(contentType)) {
        return const _NetworkImageDecision(showImage: true);
      }

      logImageDecodeIssueOnce(
        'non-image-content-type|${widget.source}|$trimmedUrl|${response.statusCode}|$contentType',
        () {
          debugPrint('[ImageDecode] Skipped URL with non-image Content-Type from ${widget.source}.');
          debugPrint('[ImageDecode] URL: $trimmedUrl');
          debugPrint('[ImageDecode] HTTP Status Code: ${response.statusCode}');
          debugPrint('[ImageDecode] Content-Type: $contentType');
        },
      );
      return const _NetworkImageDecision(showImage: false);
    } catch (error) {
      logImageDecodeIssueOnce(
        'content-type-check-failed|${widget.source}|$trimmedUrl',
        () {
          debugPrint('[ImageDecode] Could not verify Content-Type for ${widget.source}; showing image fallback.');
          debugPrint('[ImageDecode] URL: $trimmedUrl');
          debugPrint('[ImageDecode] Error: $error');
        },
      );
      return const _NetworkImageDecision(showImage: false);
    }
  }

  Widget _buildImage(String trimmedUrl) {
    return CachedNetworkImage(
      imageUrl: trimmedUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheWidth: widget.cacheWidth ?? 720,
      maxWidthDiskCache: 1280,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) =>
          widget.loading ?? _fallback(icon: Icons.image_outlined),
      errorWidget: (context, url, error) {
        logImageDecodeIssueOnce(
          'network-image-error|${widget.source}|$trimmedUrl|$error',
          () {
            debugPrint('[ImageDecode] Failed to load image from ${widget.source}.');
            debugPrint('[ImageDecode] URL: $trimmedUrl');
            debugPrint('[ImageDecode] Error: $error');
          },
        );
        return _fallback();
      },
    );
  }

  Widget _fallback({IconData icon = Icons.broken_image_outlined}) {
    if (widget.fallback != null) return widget.fallback!;
    return Container(
      width: widget.width,
      height: widget.height,
      color: const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: Icon(icon, color: const Color(0xFF9CA3AF)),
    );
  }
}

class _NetworkImageDecision {
  const _NetworkImageDecision({required this.showImage});

  final bool showImage;
}