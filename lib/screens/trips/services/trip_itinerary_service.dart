import 'dart:async';
import 'dart:convert';

import 'package:assignment/core/config/api_config.dart';
import 'package:http/http.dart' as http;

import '../models/destination.dart';

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

class TripItineraryService {
  TripItineraryService({
    http.Client? client,
    this.timeout = const Duration(minutes: 5),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  Future<TripItineraryResult> generate({
    required List<SelectedDestination> destinations,
    required DateTime departureDate,
    required DateTime returnDate,
    required int peopleCount,
    required double budgetPerPerson,
    required String departurePoint,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/trip/generate-itinerary'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'destinations': destinations
                  .map(
                    (item) => {
                      'id': item.destination.id,
                      'name': item.destination.name,
                      'region': item.destination.region,
                      'fromLabel': item.fromLabel,
                    },
                  )
                  .toList(),
              'departureDate': _dateOnly(departureDate),
              'returnDate': _dateOnly(returnDate),
              'peopleCount': peopleCount,
              'budgetPerPerson': budgetPerPerson,
              'departurePoint': departurePoint,
            }),
          )
          .timeout(timeout);

      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return TripItineraryResult.fromJson(
          jsonDecode(body) as Map<String, dynamic>,
        );
      }

      throw TripItineraryException(_serverMessage(body, response.statusCode));
    } on TimeoutException {
      throw const TripItineraryException('AI took too long to respond.');
    } on http.ClientException {
      throw const TripItineraryException('Cannot connect to backend.');
    } on FormatException {
      throw const TripItineraryException('Cannot parse backend response.');
    } on TripItineraryException {
      rethrow;
    } catch (e) {
      throw TripItineraryException('Unexpected error: $e');
    }
  }

  Future<List<TripItineraryHistoryItem>> history() async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.baseUrl}/api/trip/itineraries'))
          .timeout(timeout);

      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        final items = decoded['items'];
        if (items is! List) {
          throw const TripItineraryException('Server did not return history.');
        }
        return items
            .whereType<Map<String, dynamic>>()
            .map(TripItineraryHistoryItem.fromJson)
            .toList();
      }

      throw TripItineraryException(_serverMessage(body, response.statusCode));
    } on TimeoutException {
      throw const TripItineraryException('Backend took too long to respond.');
    } on http.ClientException {
      throw const TripItineraryException('Cannot connect to backend.');
    } on FormatException {
      throw const TripItineraryException('Cannot parse backend response.');
    } on TripItineraryException {
      rethrow;
    } catch (e) {
      throw TripItineraryException('Unexpected error: $e');
    }
  }

  void dispose() => _client.close();

  static String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String _serverMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded['detail'] as String? ??
            decoded['message'] as String? ??
            decoded['title'] as String? ??
            'Server error $statusCode';
      }
    } catch (_) {
      // Use fallback below.
    }
    return 'Server error $statusCode';
  }
}
