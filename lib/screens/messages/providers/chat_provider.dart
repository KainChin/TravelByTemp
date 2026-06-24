import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';

/// Holds chat state for the Messages screen: the message list, loading /
/// typing flags, and the [sendMessage] use case. Backed by [ChatService],
/// which is the only class allowed to perform network calls.
class ChatProvider extends ChangeNotifier {
  ChatProvider({ChatService? chatService}) : _chatService = chatService ?? ChatService();

  final ChatService _chatService;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Adds the initial AI greeting using the logged-in user's name.
  /// Call once, right after the provider is created — does nothing if the
  /// conversation already has messages (e.g. after a hot reload).
  void addInitialGreeting(String userName) {
    if (_messages.isNotEmpty) return;
    _messages.add(
      ChatMessage(
        id: _generateId(),
        message: 'Xin chào $userName! 👋\nMình có thể giúp gì cho chuyến đi của bạn hôm nay?',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// Sends [text] as a user message, then awaits and appends the AI reply.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _messages.add(
      ChatMessage(
        id: _generateId(),
        message: trimmed,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
        isSent: true,
      ),
    );
    _isLoading = true;
    _isTyping = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reply = await _chatService.sendMessage(trimmed);
      _messages.add(
        ChatMessage(
          id: _generateId(),
          message: reply,
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        ),
      );
    } on ChatServiceException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> sendImageMessage({
    required String text,
    required XFile image,
  }) async {
    final trimmed = text.trim().isEmpty ? 'Hãy đọc ảnh này và gợi ý lịch trình du lịch.' : text.trim();
    if (_isLoading) return;

    final bytes = await image.readAsBytes();
    _messages.add(
      ChatMessage(
        id: _generateId(),
        message: trimmed,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
        isSent: true,
        imageBytes: bytes,
        imageName: image.name,
      ),
    );
    _isLoading = true;
    _isTyping = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reply = await _chatService.sendImageMessage(
        message: trimmed,
        imageBytes: bytes,
        fileName: image.name.isEmpty ? 'travel-image.jpg' : image.name,
      );
      _messages.add(
        ChatMessage(
          id: _generateId(),
          message: reply,
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        ),
      );
    } on ChatServiceException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      _isTyping = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }

  void dismissError() {
    _errorMessage = null;
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();

  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }
}
