import 'itinerary.dart';

/// Who sent a given [ChatMessage].
enum MessageSender { user, ai }

/// A single chat message rendered in the Messages screen.
///
/// [itinerary] is optional and only populated when the AI response should be
/// followed by an [ItineraryCard] (e.g. once the backend starts returning
/// structured trip data alongside its plain-text reply).
class ChatMessage {
  final String id;
  final String message;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isSent;
  final ItineraryPlan? itinerary;

  const ChatMessage({
    required this.id,
    required this.message,
    required this.sender,
    required this.timestamp,
    this.isSent = false,
    this.itinerary,
  });

  bool get isAi => sender == MessageSender.ai;
  bool get isUser => sender == MessageSender.user;

  ChatMessage copyWith({
    String? message,
    bool? isSent,
    ItineraryPlan? itinerary,
  }) {
    return ChatMessage(
      id: id,
      message: message ?? this.message,
      sender: sender,
      timestamp: timestamp,
      isSent: isSent ?? this.isSent,
      itinerary: itinerary ?? this.itinerary,
    );
  }
}
