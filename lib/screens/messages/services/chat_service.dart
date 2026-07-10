import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:assignment/core/config/api_config.dart';

/// Thrown by [ChatService] for any recoverable failure (timeout, no network,
/// non-200 response, malformed body). The Flutter app should never talk to
/// Ollama directly — it always goes through the .NET backend below.
///
/// Flutter  ──HTTP──>  .NET Backend  ──>  Ollama (local)
class ChatServiceException implements Exception {
  final String message;
  ChatServiceException(this.message);

  @override
  String toString() => message;
}

class ChatService {
  /// Base endpoint exposed by the .NET backend. Update this to your machine's
  /// LAN IP (e.g. http://192.168.1.10:5000/api/chat) when testing on a
  /// physical device, or http://10.0.2.2:5000/api/chat for the Android
  /// emulator — see the "Backend connection" notes for details.
  final http.Client _client;
  final Duration timeout;
  final List<http.Client> _extraClients = [];

  ChatService({http.Client? client, this.timeout = const Duration(seconds: 90)})
      : _client = client ?? http.Client();

  /// Hủy tất cả request đang chờ (đóng các client tạm). Sau khi gọi, các
  /// `sendMessage` đang chờ sẽ nhận `http.ClientException` và provider sẽ
  /// hiển thị lỗi cho người dùng.
  void cancelAll() {
    for (final client in _extraClients) {
      client.close();
    }
    _extraClients.clear();
  }

  /// Sends [message] to the backend and returns the AI's plain-text reply.
  Future<String> sendMessage(String message) async {
    final client = http.Client();
    _extraClients.add(client);
    try {
      final response = await client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/chat'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message}),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic> && decoded['response'] is String) {
          return decoded['response'] as String;
        }
        throw ChatServiceException('Phản hồi từ server không đúng định dạng.');
      }

      throw ChatServiceException(
        'Server trả về lỗi (mã ${response.statusCode}). Vui lòng thử lại.',
      );
    } on TimeoutException {
      throw ChatServiceException(
        'Hết thời gian chờ phản hồi (${timeout.inSeconds}s). Có thể backend đang bận — thử lại sau.',
      );
    } on http.ClientException {
      throw ChatServiceException(
        'Không thể kết nối tới server. Kiểm tra kết nối mạng hoặc backend.',
      );
    } on FormatException {
      throw ChatServiceException('Không thể đọc phản hồi từ server.');
    } on ChatServiceException {
      rethrow;
    } catch (e) {
      throw ChatServiceException('Đã xảy ra lỗi không xác định: $e');
    } finally {
      _extraClients.remove(client);
      client.close();
    }
  }

  Future<String> sendImageMessage({
    required String message,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final client = http.Client();
    _extraClients.add(client);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/chat-ai'),
      )
        ..fields['message'] = message
        ..files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: fileName,
          ),
        );

      final streamed = await client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic> && decoded['response'] is String) {
          return decoded['response'] as String;
        }
        throw ChatServiceException('Phản hồi từ server không đúng định dạng.');
      }

      final detail = _readProblemDetail(response);
      throw ChatServiceException(
        detail ?? 'Server trả về lỗi (mã ${response.statusCode}). Vui lòng thử lại.',
      );
    } on TimeoutException {
      throw ChatServiceException(
        'Hết thời gian chờ phản hồi (${timeout.inSeconds}s). Có thể backend đang bận — thử lại sau.',
      );
    } on http.ClientException {
      throw ChatServiceException(
        'Không thể kết nối tới server. Kiểm tra kết nối mạng hoặc backend.',
      );
    } on FormatException {
      throw ChatServiceException('Không thể đọc phản hồi từ server.');
    } on ChatServiceException {
      rethrow;
    } catch (e) {
      throw ChatServiceException('Đã xảy ra lỗi không xác định: $e');
    } finally {
      _extraClients.remove(client);
      client.close();
    }
  }

  String? _readProblemDetail(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return decoded['detail'] as String? ?? decoded['title'] as String?;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  void dispose() => _client.close();
}

