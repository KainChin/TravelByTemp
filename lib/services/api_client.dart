import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:assignment/core/config/api_config.dart';
import 'package:assignment/models/auth_session.dart';
import 'package:assignment/models/destination.dart';

class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> _decode(http.Response res) async {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return {};
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw ApiException(
      res.body.isNotEmpty ? res.body : 'HTTP ${res.statusCode}',
      res.statusCode,
    );
  }

  Future<List<dynamic>> _decodeList(http.Response res) async {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw ApiException(res.body, res.statusCode);
  }

  Future<AuthSession> login(String username, String password) async {
    final res = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
      headers: _headers,
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = await _decode(res);
    final session = AuthSession(
      accessToken: data['accessToken'] as String,
      user: AuthUser.fromJson(data),
    );
    setToken(session.accessToken);
    return session;
  }

  Future<List<Destination>> fetchDestinations({
    String? region,
    String? category,
    double? maxBudget,
  }) async {
    final q = <String, String>{};
    if (region != null) q['region'] = region;
    if (category != null) q['category'] = category;
    if (maxBudget != null) q['maxBudget'] = maxBudget.toString();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/destinations')
        .replace(queryParameters: q.isEmpty ? null : q);
    final res = await _client.get(uri, headers: _headers);
    final list = await _decodeList(res);
    return list.map((e) => Destination.fromApi(e as Map<String, dynamic>)).toList();
  }

  Future<WeatherSnapshot> fetchWeather(double lat, double lon) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/weather/current').replace(
      queryParameters: {'latitude': '$lat', 'longitude': '$lon'},
    );
    final res = await _client.get(uri, headers: _headers);
    final data = await _decode(res);
    return WeatherSnapshot(
      temperatureC: (data['temperatureC'] as num).toDouble(),
      description: data['description'] as String? ?? '',
    );
  }

  Future<AiRecommendResult> recommend({
    required double latitude,
    required double longitude,
    required String locationName,
    required double budgetInput,
    required int totalDays,
    required String preferenceInput,
  }) async {
    final res = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/ai/recommend'),
      headers: _headers,
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'budgetInput': budgetInput,
        'totalDays': totalDays,
        'preferenceInput': preferenceInput,
        'topK': 5,
      }),
    );
    final data = await _decode(res);
    return AiRecommendResult.fromJson(data);
  }
}

class WeatherSnapshot {
  const WeatherSnapshot({required this.temperatureC, required this.description});
  final double temperatureC;
  final String description;
}

class AiRecommendResult {
  AiRecommendResult({
    required this.scheduleId,
    required this.title,
    required this.summary,
    required this.currentTemperature,
    required this.currentWeatherDescription,
    required this.recommendedDestinations,
    required this.dailyPlan,
  });

  final String scheduleId;
  final String title;
  final String summary;
  final double currentTemperature;
  final String currentWeatherDescription;
  final List<AiRecommendedDest> recommendedDestinations;
  final List<AiDailyPlan> dailyPlan;

  factory AiRecommendResult.fromJson(Map<String, dynamic> json) {
    return AiRecommendResult(
      scheduleId: json['scheduleId'] as String,
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      currentTemperature: (json['currentTemperature'] as num?)?.toDouble() ?? 0,
      currentWeatherDescription:
          json['currentWeatherDescription'] as String? ?? '',
      recommendedDestinations: (json['recommendedDestinations'] as List? ?? [])
          .map((e) => AiRecommendedDest.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyPlan: (json['dailyPlan'] as List? ?? [])
          .map((e) => AiDailyPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AiRecommendedDest {
  AiRecommendedDest({
    required this.destinationId,
    required this.name,
    required this.reason,
    required this.weatherFit,
  });

  final String destinationId;
  final String name;
  final String reason;
  final String weatherFit;

  factory AiRecommendedDest.fromJson(Map<String, dynamic> json) => AiRecommendedDest(
        destinationId: json['destinationId'] as String,
        name: json['name'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        weatherFit: json['weatherFit'] as String? ?? '',
      );
}

class AiDailyPlan {
  AiDailyPlan({required this.day, required this.items});
  final int day;
  final List<AiDailyPlanItem> items;

  factory AiDailyPlan.fromJson(Map<String, dynamic> json) => AiDailyPlan(
        day: json['day'] as int? ?? 1,
        items: (json['items'] as List? ?? [])
            .map((e) => AiDailyPlanItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AiDailyPlanItem {
  AiDailyPlanItem({
    required this.destinationId,
    required this.time,
    required this.activity,
    this.note,
  });

  final String destinationId;
  final String time;
  final String activity;
  final String? note;

  factory AiDailyPlanItem.fromJson(Map<String, dynamic> json) => AiDailyPlanItem(
        destinationId: json['destinationId'] as String,
        time: json['time'] as String? ?? '',
        activity: json['activity'] as String? ?? '',
        note: json['note'] as String?,
      );
}
