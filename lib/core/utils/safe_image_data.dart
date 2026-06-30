import 'dart:convert';

import 'package:flutter/foundation.dart';

bool isSupportedImageBytes(Uint8List bytes) {
  if (bytes.length < 4) return false;

  final isPng = bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A;
  final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
  final isGif = bytes.length >= 6 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x38;
  final isWebp = bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50;

  return isPng || isJpeg || isGif || isWebp;
}

bool isSupportedImageContentType(String? contentType) {
  final value = contentType?.toLowerCase().split(';').first.trim();
  if (value == null || value.isEmpty) return false;
  return value == 'image/jpeg' ||
      value == 'image/jpg' ||
      value == 'image/png' ||
      value == 'image/gif' ||
      value == 'image/webp';
}

Uint8List? safeBase64ImageDecode(
  String? value, {
  required String source,
}) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return null;

  try {
    final bytes = base64Decode(raw);
    if (isSupportedImageBytes(bytes)) return bytes;
    logInvalidImageBytes(source: source, bytes: bytes);
    return null;
  } on FormatException catch (error) {
    debugPrint('[ImageDecode] Invalid base64 from $source: $error');
    debugPrint('[ImageDecode] Body preview: ${_previewText(raw.codeUnits)}');
    return null;
  }
}

void logInvalidImageBytes({
  required String source,
  required Uint8List bytes,
  int? httpStatusCode,
  String? contentType,
  String? url,
}) {
  final header = bytes.take(12).map((byte) => '0x${byte.toRadixString(16).padLeft(2, '0')}').join(' ');
  debugPrint('[ImageDecode] Invalid image bytes from $source');
  if (url != null) debugPrint('[ImageDecode] URL: $url');
  if (httpStatusCode != null) debugPrint('[ImageDecode] HTTP Status Code: $httpStatusCode');
  if (contentType != null) debugPrint('[ImageDecode] Content-Type: $contentType');
  debugPrint('[ImageDecode] File header: [$header]');
  debugPrint('[ImageDecode] Response Body preview: ${_previewText(bytes)}');
}

String _previewText(Iterable<int> bytes) {
  return utf8.decode(bytes.take(160).toList(), allowMalformed: true).replaceAll(RegExp(r'\s+'), ' ').trim();
}
