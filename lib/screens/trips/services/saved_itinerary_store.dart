import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedItineraryItem {
  const SavedItineraryItem({
    required this.id,
    required this.title,
    required this.savedAt,
    required this.itinerary,
  });

  final String id;
  final String title;
  final DateTime savedAt;
  final Map<String, dynamic> itinerary;

  factory SavedItineraryItem.fromJson(Map<String, dynamic> json) {
    final rawItinerary = json['itinerary'];
    return SavedItineraryItem(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? 'Hành trình đã lưu'}',
      savedAt: DateTime.tryParse('${json['savedAt'] ?? ''}') ?? DateTime.now(),
      itinerary: rawItinerary is Map<String, dynamic>
          ? rawItinerary
          : Map<String, dynamic>.from(rawItinerary is Map ? rawItinerary : const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'savedAt': savedAt.toIso8601String(),
        'itinerary': itinerary,
      };
}

class SavedItineraryStore {
  static const _key = 'vietai_saved_itineraries';

  static Future<List<SavedItineraryItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((item) => SavedItineraryItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<void> save(Map<String, dynamic> itinerary) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await load();
    final title = '${itinerary['title'] ?? 'Hành trình đã lưu'}'.trim();
    final id = '${itinerary['id'] ?? itinerary['itineraryId'] ?? title}-${DateTime.now().millisecondsSinceEpoch}';
    final next = [
      SavedItineraryItem(
        id: id,
        title: title.isEmpty ? 'Hành trình đã lưu' : title,
        savedAt: DateTime.now(),
        itinerary: Map<String, dynamic>.from(itinerary),
      ),
      ...items.where((item) => item.title != title),
    ];
    await prefs.setString(
      _key,
      jsonEncode(next.map((item) => item.toJson()).toList()),
    );
  }

  static Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await load();
    await prefs.setString(
      _key,
      jsonEncode(items.where((item) => item.id != id).map((item) => item.toJson()).toList()),
    );
  }
}
