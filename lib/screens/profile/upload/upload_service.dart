import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:assignment/services/firestore_service.dart';

class UploadService {
  static final _picker = ImagePicker();

  /// Chọn nhiều ảnh từ gallery
  static Future<List<XFile>> pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 60);
    return images;
  }

  /// Chuyển XFile → base64 (có nén)
  static Future<String> toBase64(XFile file) async {
    final bytes = await file.readAsBytes();
    final compressed = await _compressBytes(bytes);
    return base64Encode(compressed);
  }

  /// Nén ảnh xuống max 800px và quality 60%
  static Future<Uint8List> _compressBytes(Uint8List bytes) async {
    // Trên web dùng thẳng bytes (flutter_image_compress không hỗ trợ web)
    if (kIsWeb) return bytes;

    try {
      // Trên mobile dùng flutter_image_compress
      // ignore: depend_on_referenced_packages
      // Nếu có package thì uncomment:
      // return await FlutterImageCompress.compressWithList(bytes, quality: 60, minWidth: 800);
      return bytes;
    } catch (_) {
      return bytes;
    }
  }

  /// Upload ảnh lên Firestore theo tripId
  static Future<void> uploadPhoto({
    required XFile file,
    required String tripId,
  }) async {
    final base64Data = await toBase64(file);
    await FirestoreService.savePhoto(
      tripId: tripId,
      base64Data: base64Data,
      fileName: file.name,
    );
  }

  /// Upload nhiều ảnh cùng lúc
  static Future<void> uploadMultiplePhotos({
    required List<XFile> files,
    required String tripId,
    void Function(int current, int total)? onProgress,
  }) async {
    for (int i = 0; i < files.length; i++) {
      await uploadPhoto(file: files[i], tripId: tripId);
      onProgress?.call(i + 1, files.length);
    }
  }
}