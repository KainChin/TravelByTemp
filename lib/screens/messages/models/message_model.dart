enum MessageType { text, itinerary }

class ItineraryStop {
  final String city;
  final String emoji;
  final int days;
  final int nights;
  final String dayLabel;

  const ItineraryStop({
    required this.city,
    required this.emoji,
    required this.days,
    required this.nights,
    required this.dayLabel,
  });
}

class MessageModel {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final List<ItineraryStop>? itineraryStops;
  final String? itineraryTitle;

  MessageModel({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.itineraryStops,
    this.itineraryTitle,
  }) : id = DateTime.now().microsecondsSinceEpoch.toString();
}