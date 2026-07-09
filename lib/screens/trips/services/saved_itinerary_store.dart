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
    final rawId = '${itinerary['id'] ?? itinerary['itineraryId'] ?? ''}'.trim();
    final stableId = rawId.isEmpty
        ? 'local-${title.toLowerCase()}-${DateTime.now().millisecondsSinceEpoch}'
        : rawId;
    final nextItem = SavedItineraryItem(
      id: stableId,
      title: title.isEmpty ? 'Hành trình đã lưu' : title,
      savedAt: DateTime.now(),
      itinerary: Map<String, dynamic>.from(itinerary),
    );
    final filtered = items.where((item) => item.id != stableId).toList();
    filtered.insert(0, nextItem);
    await prefs.setString(
      _key,
      jsonEncode(filtered.map((item) => item.toJson()).toList()),
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

  /// Cập nhật nội dung itinerary của 1 item (không thay đổi title hay savedAt).
  /// Trả về true nếu tìm thấy id và cập nhật thành công.
  static Future<bool> updateItinerary(String id, Map<String, dynamic> itinerary) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await load();
    var found = false;
    final updated = items.map((item) {
      if (item.id != id) return item;
      found = true;
      return SavedItineraryItem(
        id: item.id,
        title: item.title,
        savedAt: item.savedAt,
        itinerary: Map<String, dynamic>.from(itinerary),
      );
    }).toList();
    if (!found) return false;
    await prefs.setString(
      _key,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
    return true;
  }

  /// Dựng text chia sẻ chuẩn cho một itinerary: tiêu đề + lộ trình + số
  /// ngày/hoạt động + tóm tắt. Được dùng chung bởi [SavedScreen] và
  /// [SavedTripDetailScreen] để 2 màn share đồng nhất.
  static String buildShareText(SavedItineraryItem item) {
    final days = item.itinerary['days'];
    final dests = <String>{};
    var dayCount = 0;
    var activityCount = 0;
    if (days is List) {
      dayCount = days.length;
      for (final day in days) {
        if (day is Map) {
          final activities = day['activities'] ?? day['schedule'];
          if (activities is List) {
            activityCount += activities.length;
            for (final a in activities) {
              if (a is Map) {
                final name = (a['destination'] ?? a['placeName'] ?? '').toString().trim();
                if (name.isNotEmpty && name.toLowerCase() != 'null') dests.add(name);
              }
            }
          }
        }
      }
    }
    final route = dests.isEmpty
        ? 'điểm đến đã chọn'
        : dests.take(5).join(' → ');
    final summary = item.itinerary['summary']?.toString().trim();
    final buffer = StringBuffer()
      ..writeln('🌏 Hành trình: ${item.title}')
      ..writeln('🗺️  Lộ trình: $route')
      ..writeln('📅 $dayCount ngày • $activityCount hoạt động');
    if (summary != null && summary.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(summary);
    }
    buffer
      ..writeln()
      ..writeln('— Lưu bởi VietAI Travel');
    return buffer.toString();
  }
}
