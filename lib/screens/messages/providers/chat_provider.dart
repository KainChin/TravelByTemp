import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';
import '../models/chat_history_item.dart';
import '../services/chat_service.dart';

const _kHistoryKey = 'chat_history_v2';
const _kCurrentSessionKey = 'chat_current_session_v2';

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

  String _currentUserName = '';
  String get currentUserName => _currentUserName;

  bool _isReady = false;
  bool get isReady => _isReady;

  String _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();

  final List<ChatHistoryItem> _history = [];
  List<ChatHistoryItem> get history => List.unmodifiable(_history);

  // ─── Storage ─────────────────────────────────────────────────────────────

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _history.map((h) => h.toJson()).toList();
      await prefs.setString(_kHistoryKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  Future<void> _saveCurrentSessionToPrefs() async {
    try {
      if (_messages.length <= 1) return; // only greeting, skip
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'sessionId': _currentSessionId,
        'messages': _messages.map((m) => m.toJson()).toList(),
      };
      await prefs.setString(_kCurrentSessionKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving current session: $e');
    }
  }

  Future<void> _clearCurrentSessionPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCurrentSessionKey);
  }

  // ─── Initialization ───────────────────────────────────────────────────────

  /// Must be called once after provider is created.
  /// Loads history + restores in-progress session, THEN shows greeting if needed.
  Future<void> initialize(String userName) async {
    _currentUserName = userName;

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Load full chat history
      final historyStr = prefs.getString(_kHistoryKey);
      if (historyStr != null) {
        final List<dynamic> jsonList = jsonDecode(historyStr);
        _history.clear();
        for (var itemJson in jsonList) {
          _history.add(ChatHistoryItem.fromJson(itemJson as Map<String, dynamic>));
        }
      }

      // 2. Restore in-progress session (if any)
      final currentStr = prefs.getString(_kCurrentSessionKey);
      if (currentStr != null) {
        final data = jsonDecode(currentStr) as Map<String, dynamic>;
        final restoredMessages = (data['messages'] as List<dynamic>)
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList();
        if (restoredMessages.length > 1) {
          // Has actual conversation (not just greeting)
          _currentSessionId = data['sessionId'] as String;
          _messages.clear();
          _messages.addAll(restoredMessages);
          _isReady = true;
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading chat data: $e');
    }

    // 3. No in-progress session → show fresh greeting
    _messages.clear();
    _messages.add(
      ChatMessage(
        id: _generateId(),
        message: 'Xin chào $_currentUserName! 👋\nMình có thể giúp gì cho chuyến đi của bạn hôm nay?',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      ),
    );
    _isReady = true;
    notifyListeners();
  }

  // ─── Session management ───────────────────────────────────────────────────

  void _archiveCurrentSession() {
    if (_messages.length <= 1) return; // Only greeting, nothing to save

    final index = _history.indexWhere((h) => h.id == _currentSessionId);
    final firstUserMsg = _messages.firstWhere(
      (m) => m.sender == MessageSender.user,
      orElse: () => _messages.last,
    );

    String timeStr = index >= 0
        ? _history[index].time
        : DateFormat('HH:mm').format(DateTime.now());

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

    _saveHistory();
  }

  /// Clears all messages and re-injects the welcome greeting.
  void clearAndRestart([String? userName]) {
    _archiveCurrentSession();
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _clearCurrentSessionPrefs();

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
    _archiveCurrentSession();

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

  // ─── Sending messages ─────────────────────────────────────────────────────

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
    // Save user message immediately so it's not lost even if app crashes
    _saveCurrentSessionToPrefs();

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
      _archiveCurrentSession();
      _saveCurrentSessionToPrefs();
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
    _saveCurrentSessionToPrefs();

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
      _archiveCurrentSession();
      _saveCurrentSessionToPrefs();
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
    // Save everything when the provider is destroyed (user leaves screen)
    _archiveCurrentSession();
    // Note: can't await here in dispose, so use fire-and-forget
    _saveCurrentSessionToPrefs();
    _saveHistory();
    _chatService.dispose();
    super.dispose();
  }
}
