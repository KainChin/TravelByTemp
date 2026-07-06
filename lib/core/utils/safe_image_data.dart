import 'dart:convert';

import 'package:flutter/foundation.dart';

final Set<String> _loggedImageDecodeIssues = <String>{};

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

bool hasSupportedImageUrlExtension(Uri uri) {
  final path = uri.path.toLowerCase();
  return path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.png') ||
      path.endsWith('.webp') ||
      path.endsWith('.gif');
}

bool isKnownNonImageUrl(Uri uri) {
  final host = uri.host.toLowerCase();
  final path = uri.path.toLowerCase();
  return host.contains('docs.google.com') ||
      host.contains('sheets.google.com') ||
      (host.contains('drive.google.com') && !path.contains('/uc')) ||
      path.endsWith('.pdf') ||
      path.endsWith('.doc') ||
      path.endsWith('.docx') ||
      path.endsWith('.xls') ||
      path.endsWith('.xlsx') ||
      path.endsWith('.csv') ||
      path.endsWith('.txt') ||
      path.endsWith('.url');
}

Uint8List? safeBase64ImageDecode(
  String? value, {
  required String source,
}) {
  final rawInput = value?.trim() ?? '';
  if (rawInput.isEmpty) return null;

  final raw = _normalizeBase64ImagePayload(rawInput, source: source);
  if (raw.isEmpty) return null;

  try {
    final bytes = base64Decode(raw);
    if (isSupportedImageBytes(bytes)) return bytes;
    logInvalidImageBytes(source: source, bytes: bytes);
    return null;
  } on FormatException catch (error) {
    _debugPrintOnce(
      'invalid-base64|$source|${raw.hashCode}',
      () {
        debugPrint('[ImageDecode] Invalid base64 from $source: $error');
        debugPrint('[ImageDecode] Body preview: ${_previewText(raw.codeUnits)}');
      },
    );
    return null;
  }
}

String _normalizeBase64ImagePayload(String raw, {required String source}) {
  if (raw.startsWith('[InternetShortcut]')) {
    _debugPrintOnce(
      'internet-shortcut|$source|${raw.hashCode}',
      () {
        debugPrint('[ImageDecode] Skipped Windows InternetShortcut data from $source.');
        debugPrint('[ImageDecode] Body preview: ${_previewText(raw.codeUnits)}');
      },
    );
    return '';
  }

  final dataUriMatch = RegExp(r'^data:([^;,]+)?(?:;[^,]*)?,(.*)$', dotAll: true)
      .firstMatch(raw);
  if (dataUriMatch == null) return raw;

  final contentType = dataUriMatch.group(1);
  if (!isSupportedImageContentType(contentType)) {
    _debugPrintOnce(
      'non-image-data-uri|$source|$contentType|${raw.hashCode}',
      () {
        debugPrint('[ImageDecode] Skipped non-image data URI from $source.');
        debugPrint('[ImageDecode] Content-Type: $contentType');
      },
    );
    return '';
  }

  return dataUriMatch.group(2)?.trim() ?? '';
}

void logInvalidImageBytes({
  required String source,
  required Uint8List bytes,
  int? httpStatusCode,
  String? contentType,
  String? url,
}) {
  final header = bytes.take(12).map((byte) => '0x${byte.toRadixString(16).padLeft(2, '0')}').join(' ');
  _debugPrintOnce(
    'invalid-bytes|$source|$url|$contentType|$header|${bytes.length}',
    () {
      debugPrint('[ImageDecode] Invalid image bytes from $source');
      if (url != null) debugPrint('[ImageDecode] URL: $url');
      if (httpStatusCode != null) debugPrint('[ImageDecode] HTTP Status Code: $httpStatusCode');
      if (contentType != null) debugPrint('[ImageDecode] Content-Type: $contentType');
      debugPrint('[ImageDecode] File header: [$header]');
      debugPrint('[ImageDecode] Response Body preview: ${_previewText(bytes)}');
    },
  );
}

void logImageDecodeIssueOnce(String key, void Function() write) {
  _debugPrintOnce(key, write);
}

void _debugPrintOnce(String key, void Function() write) {
  if (!_loggedImageDecodeIssues.add(key)) return;
  write();
}

String _previewText(Iterable<int> bytes) {
  return utf8.decode(bytes.take(160).toList(), allowMalformed: true).replaceAll(RegExp(r'\s+'), ' ').trim();
}
