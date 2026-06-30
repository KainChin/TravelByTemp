import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../utils/safe_image_data.dart';

class SafeMemoryImage extends StatelessWidget {
  const SafeMemoryImage({
    super.key,
    required this.bytes,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  final Uint8List? bytes;
  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final data = bytes;
    if (data == null || !isSupportedImageBytes(data)) {
      if (data != null) {
        logInvalidImageBytes(source: source, bytes: data);
      }
      return placeholder ?? _ImageFallback(width: width, height: height);
    }

    return Image.memory(
      data,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[ImageDecode] Flutter failed to render memory image from $source: $error');
        return placeholder ?? _ImageFallback(width: width, height: height);
      },
    );
  }
}

class SafeBase64Image extends StatelessWidget {
  const SafeBase64Image({
    super.key,
    required this.base64,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  final String? base64;
  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final bytes = safeBase64ImageDecode(base64, source: source);
    if (bytes == null) {
      return placeholder ?? _ImageFallback(width: width, height: height);
    }
    return SafeMemoryImage(
      bytes: bytes,
      source: source,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade500),
    );
  }
}
