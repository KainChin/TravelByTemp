import 'package:assignment/screens/messages/models/chat_message.dart';

class ChatHistoryItem {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final String imageUrl;
  final List<ChatMessage> messages;

  const ChatHistoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.imageUrl,
    required this.messages,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'time': time,
      'imageUrl': imageUrl,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) {
    return ChatHistoryItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      time: json['time'] as String,
      imageUrl: json['imageUrl'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
