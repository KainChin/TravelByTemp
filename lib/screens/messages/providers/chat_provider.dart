import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/ai_service.dart';

class ChatProvider extends ChangeNotifier {
  final _aiService = AiService();
  final List<MessageModel> messages = [];
  final List<Map<String, String>> _history = [];
  bool isLoading = false;

  final quickSuggestions = const [
    '🏖️ Gợi ý điểm đến hè này',
    '🎒 Cần chuẩn bị gì khi đi Đà Lạt?',
    '💰 Lịch trình Hội An 3 ngày 2 đêm',
    '🍜 Ẩm thực đặc sắc miền Trung',
  ];

  Future<void> send(String text) async {
    if (text.trim().isEmpty || isLoading) return;

    messages.add(MessageModel(
      content: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _history.add({'role': 'user', 'content': text.trim()});
    isLoading = true;
    notifyListeners();

    final reply = await _aiService.sendMessage(_history);

    messages.add(MessageModel(
      content: reply,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    _history.add({'role': 'assistant', 'content': reply});
    isLoading = false;
    notifyListeners();
  }

  void clear() {
    messages.clear();
    _history.clear();
    isLoading = false;
    notifyListeners();
  }
}
