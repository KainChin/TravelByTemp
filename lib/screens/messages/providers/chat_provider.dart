import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../models/chat_history_item.dart';
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

  /// Đã gửi bao nhiêu request và backend trả lời bao nhiêu. Khác nhau →
  /// request hiện đang chờ xử lý. UI có thể hiển thị nút "Hủy".
  int _pendingRequests = 0;
  bool get hasPendingRequest => _pendingRequests > 0;

  String _currentUserName = '';
  String get currentUserName => _currentUserName;

  String _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();

  final List<ChatHistoryItem> _history = [];
  List<ChatHistoryItem> get history => List.unmodifiable(_history);

  /// Adds the initial AI greeting using the logged-in user's name.
  /// Call once, right after the provider is created — does nothing if the
  /// conversation already has messages (e.g. after a hot reload).
  void addInitialGreeting(String userName) {
    if (_messages.isNotEmpty) return;
    _currentUserName = userName;
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

  void _saveCurrentSession() {
    if (_messages.length > 1) {
      final index = _history.indexWhere((h) => h.id == _currentSessionId);
      final firstUserMsg = _messages.firstWhere(
        (m) => m.sender == MessageSender.user,
        orElse: () => _messages.last,
      );
      
      // Prevent updating time if it's already in history (unless you want it bumped)
      String timeStr = DateFormat('HH:mm').format(DateTime.now());
      if (index >= 0) {
        timeStr = _history[index].time;
      }

      final item = ChatHistoryItem(
        id: _currentSessionId,
        title: 'Cuộc trò chuyện mới',
        subtitle: firstUserMsg.message,
        time: timeStr,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c9/Dragon_Bridge.jpg/1280px-Dragon_Bridge.jpg',
        messages: List.from(_messages),
      );

      if (index >= 0) {
        _history[index] = item;
      } else {
        _history.insert(0, item);
      }
    }
  }

  /// Clears all messages and re-injects the welcome greeting.
  /// Call this when user taps "Mới chat" or "Làm mới chat".
  void clearAndRestart([String? userName]) {
    _saveCurrentSession();
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();

    _messages.clear();
    _isLoading = false;
    _isTyping = false;
    _errorMessage = null;
    final name = (userName != null && userName.isNotEmpty) ? userName : _currentUserName;
    _currentUserName = name;
    _messages.add(
      ChatMessage(
        id: _generateId(),
        message: 'Xin chào $name! 👋\nMình có thể giúp gì cho chuyến đi của bạn hôm nay?',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// Loads an existing session from history
  void loadSession(String sessionId) {
    _saveCurrentSession();
    
    final index = _history.indexWhere((h) => h.id == sessionId);
    if (index >= 0) {
      _currentSessionId = sessionId;
      _messages.clear();
      _messages.addAll(_history[index].messages);
      _isLoading = false;
      _isTyping = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Sends [text] as a user message, then awaits and appends the AI reply.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    final userMsg = ChatMessage(
      id: _generateId(),
      message: trimmed,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
      isSent: true,
    );
    _messages.add(userMsg);
    _isLoading = true;
    _isTyping = true;
    _pendingRequests++;
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
      _saveCurrentSession();
    } on ChatServiceException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi không xác định: $e';
    } finally {
      _pendingRequests = (_pendingRequests - 1).clamp(0, 1 << 30);
      _isLoading = _pendingRequests > 0;
      _isTyping = _pendingRequests > 0;
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
    _pendingRequests++;
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
      _saveCurrentSession();
    } on ChatServiceException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi không xác định: $e';
    } finally {
      _pendingRequests = (_pendingRequests - 1).clamp(0, 1 << 30);
      _isLoading = _pendingRequests > 0;
      _isTyping = _pendingRequests > 0;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }

  /// Hủy tất cả request AI đang chờ. User bấm "Dừng chờ" khi backend quá
  /// chậm. Provider sẽ revert UI về trạng thái sẵn sàng nhận tin mới.
  void cancelPending() {
    if (_pendingRequests == 0) return;
    _chatService.cancelAll();
    _isLoading = false;
    _isTyping = false;
    _pendingRequests = 0;
    _errorMessage = null;
    _messages.add(
      ChatMessage(
        id: _generateId(),
        message: '⏹ Đã dừng yêu cầu. Bạn có thể nhắn lại.',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      ),
    );
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
