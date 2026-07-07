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
}
