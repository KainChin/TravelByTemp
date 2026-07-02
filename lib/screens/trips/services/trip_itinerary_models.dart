// ignore_for_file: use_string_in_part_of_directives
part of trip_itinerary_service;

class TripItineraryException implements Exception {
  const TripItineraryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TripItineraryResult {
  const TripItineraryResult({
    required this.response,
    required this.itinerary,
    this.itineraryId,
  });

  final String response;
  final Map<String, dynamic> itinerary;
  final String? itineraryId;

  factory TripItineraryResult.fromJson(Map<String, dynamic> json) {
    final itinerary = json['itinerary'];
    if (itinerary is! Map<String, dynamic>) {
      throw const TripItineraryException('Server did not return an itinerary.');
    }

    return TripItineraryResult(
      response: json['response'] as String? ?? '',
      itinerary: itinerary,
      itineraryId: json['itineraryId'] as String?,
    );
  }
}

class TripItineraryHistoryItem {
  const TripItineraryHistoryItem({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.itinerary,
    this.aiModel,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final Map<String, dynamic> itinerary;
  final String? aiModel;

  factory TripItineraryHistoryItem.fromJson(Map<String, dynamic> json) {
    final itinerary = json['itinerary'];
    if (itinerary is! Map<String, dynamic>) {
      throw const TripItineraryException('History item has invalid itinerary.');
    }

    return TripItineraryHistoryItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ??
          itinerary['title'] as String? ??
          'AI itinerary',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      itinerary: itinerary,
      aiModel: json['aiModel'] as String?,
    );
  }
}
