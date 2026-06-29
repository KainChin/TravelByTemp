import 'dart:async';
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
    throw ApiException(_errorMessage(res), res.statusCode);
  }

  Future<List<dynamic>> _decodeList(http.Response res) async {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw ApiException(_errorMessage(res), res.statusCode);
  }

  Future<void> _decodeEmpty(http.Response res) async {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw ApiException(_errorMessage(res), res.statusCode);
  }

  String _errorMessage(http.Response res) {
    if (res.body.isEmpty) return 'HTTP ${res.statusCode}';
    try {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ??
            data['title'] as String? ??
            data['detail'] as String? ??
            res.body;
      }
    } catch (_) {
      // Fall through to raw body when the API returns plain text.
    }
    return res.body;
  }

  Future<AuthSession> login(String username, String password) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/login');
    final res = await _postJson(
      uri,
      {'username': username, 'password': password},
    );
    final data = await _decode(res);
    final session = AuthSession.fromJson(data);
    setToken(session.accessToken);
    return session;
  }

  Future<http.Response> _postJson(Uri uri, Map<String, dynamic> body) async {
    try {
      return await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(ApiConfig.requestTimeout);
    } on TimeoutException {
      throw ApiException(
        'Không kết nối được backend tại $uri sau ${ApiConfig.requestTimeout.inSeconds}s. '
        'Nếu chạy trên điện thoại thật, hãy chắc chắn điện thoại và laptop cùng Wi-Fi, '
        'backend đang chạy bằng 0.0.0.0:5000, và IP trong ApiConfig đúng.',
      );
    } on http.ClientException catch (e) {
      throw ApiException('Không gọi được backend tại $uri.\n$e');
    }
  }

  Future<AuthSession> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
  }) async {
    final res = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'fullName': fullName,
      }),
    );
    final session = AuthSession.fromJson(await _decode(res));
    setToken(session.accessToken);
    return session;
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final res = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/refresh'),
      headers: _headers,
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    final session = AuthSession.fromJson(await _decode(res));
    setToken(session.accessToken);
    return session;
  }

  Future<AuthUser> updateProfile({
    required String username,
    required String email,
    required String fullName,
    String? bio,
    String? phone,
  }) async {
    final res = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/me'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'email': email,
        'fullName': fullName,
        'bio': bio,
        'phone': phone,
      }),
    );
    return AuthUser.fromJson(await _decode(res));
  }

  Future<List<Destination>> fetchDestinations({
    String? region,
    String? category,
    double? maxBudget,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    final q = <String, String>{};
    if (region != null) q['region'] = region;
    if (category != null) q['category'] = category;
    if (maxBudget != null) q['maxBudget'] = maxBudget.toString();
    if (latitude != null) q['latitude'] = latitude.toString();
    if (longitude != null) q['longitude'] = longitude.toString();
    if (radiusKm != null) q['radiusKm'] = radiusKm.toString();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/destinations')
        .replace(queryParameters: q.isEmpty ? null : q);
    final res = await _client.get(uri, headers: _headers);
    final list = await _decodeList(res);
    return list.map((e) => Destination.fromApi(e as Map<String, dynamic>)).toList();
  }

  Future<Destination> fetchDestination(String id) async {
    final res = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/destinations/$id'),
      headers: _headers,
    );
    return Destination.fromApi(await _decode(res));
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

  Future<List<ScheduleSummary>> fetchSchedules() async {
    final res = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/schedules'),
      headers: _headers,
    );
    final list = await _decodeList(res);
    return list
        .map((e) => ScheduleSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ScheduleDetail> fetchSchedule(String id) async {
    final res = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/schedules/$id'),
      headers: _headers,
    );
    final data = await _decode(res);
    return ScheduleDetail.fromJson(data);
  }

  Future<ScheduleDetail> createSchedule({
    required String title,
    required int totalDays,
    required double budgetInput,
    String? preferenceInput,
    double? userLatitude,
    double? userLongitude,
    String? userLocationName,
  }) async {
    final res = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/schedules'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'totalDays': totalDays,
        'budgetInput': budgetInput,
        'preferenceInput': preferenceInput,
        'userLatitude': userLatitude,
        'userLongitude': userLongitude,
        'userLocationName': userLocationName,
      }),
    );
    return ScheduleDetail.fromJson(await _decode(res));
  }

  Future<void> deleteSchedule(String id) async {
    final res = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/schedules/$id'),
      headers: _headers,
    );
    await _decodeEmpty(res);
  }

  Future<ScheduleDetail> updateScheduleDays(String id, int totalDays) async {
    final res = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/schedules/$id/days'),
      headers: _headers,
      body: jsonEncode({'totalDays': totalDays}),
    );
    return ScheduleDetail.fromJson(await _decode(res));
  }

  Future<ScheduleDetail> addScheduleActivity({
    required String scheduleId,
    required String destinationId,
    required int dayNumber,
    int? orderInDay,
    String? estimatedTime,
    String? note,
    String? aiReason,
    String? weatherFitNote,
  }) async {
    final res = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/schedules/$scheduleId/activities'),
      headers: _headers,
      body: jsonEncode({
        'destinationId': destinationId,
        'dayNumber': dayNumber,
        'orderInDay': orderInDay,
        'estimatedTime': estimatedTime,
        'note': note,
        'aiReason': aiReason,
        'weatherFitNote': weatherFitNote,
      }),
    );
    return ScheduleDetail.fromJson(await _decode(res));
  }

  Future<ScheduleDetail> updateScheduleActivity({
    required String scheduleId,
    required String activityId,
    String? destinationId,
    int? dayNumber,
    int? orderInDay,
    String? estimatedTime,
    String? note,
    String? aiReason,
    String? weatherFitNote,
  }) async {
    final res = await _client.put(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/schedules/$scheduleId/activities/$activityId',
      ),
      headers: _headers,
      body: jsonEncode({
        'destinationId': destinationId,
        'dayNumber': dayNumber,
        'orderInDay': orderInDay,
        'estimatedTime': estimatedTime,
        'note': note,
        'aiReason': aiReason,
        'weatherFitNote': weatherFitNote,
      }),
    );
    return ScheduleDetail.fromJson(await _decode(res));
  }

  Future<ScheduleDetail> deleteScheduleActivity({
    required String scheduleId,
    required String activityId,
  }) async {
    final res = await _client.delete(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/schedules/$scheduleId/activities/$activityId',
      ),
      headers: _headers,
    );
    return ScheduleDetail.fromJson(await _decode(res));
  }

  Future<List<Comment>> fetchComments(String destinationId) async {
    final res = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/destinations/$destinationId/comments'),
      headers: _headers,
    );
    final list = await _decodeList(res);
    return list.map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Comment> createComment({
    required String destinationId,
    required int rating,
    String? content,
  }) async {
    final res = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/destinations/$destinationId/comments'),
      headers: _headers,
      body: jsonEncode({'rating': rating, 'content': content}),
    );
    return Comment.fromJson(await _decode(res));
  }

  Future<Comment> updateComment({
    required String id,
    int? rating,
    String? content,
  }) async {
    final res = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}/api/comments/$id'),
      headers: _headers,
      body: jsonEncode({'rating': rating, 'content': content}),
    );
    return Comment.fromJson(await _decode(res));
  }

  Future<void> deleteComment(String id) async {
    final res = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/comments/$id'),
      headers: _headers,
    );
    await _decodeEmpty(res);
  }

  Future<List<FavoriteDestination>> fetchFavorites() async {
    final res = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/favorites'),
      headers: _headers,
    );
    final list = await _decodeList(res);
    return list
        .map((e) => FavoriteDestination.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FavoriteDestination> addFavorite(String destinationId) async {
    final res = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/favorites/$destinationId'),
      headers: _headers,
    );
    return FavoriteDestination.fromJson(await _decode(res));
  }

  Future<void> deleteFavorite(String destinationId) async {
    final res = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/favorites/$destinationId'),
      headers: _headers,
    );
    await _decodeEmpty(res);
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

class ScheduleSummary {
  ScheduleSummary({
    required this.id,
    required this.title,
    required this.totalDays,
    required this.budgetInput,
    required this.preferenceInput,
    required this.userLocationName,
    required this.currentTemperature,
    required this.currentWeatherDescription,
    required this.generatedAt,
  });

  final String id;
  final String title;
  final int totalDays;
  final double budgetInput;
  final String? preferenceInput;
  final String? userLocationName;
  final double? currentTemperature;
  final String? currentWeatherDescription;
  final DateTime generatedAt;

  factory ScheduleSummary.fromJson(Map<String, dynamic> json) {
    return ScheduleSummary(
      id: '${json['id']}',
      title: json['title'] as String? ?? 'Untitled trip',
      totalDays: json['totalDays'] as int? ?? 1,
      budgetInput: (json['budgetInput'] as num?)?.toDouble() ?? 0,
      preferenceInput: json['preferenceInput'] as String?,
      userLocationName: json['userLocationName'] as String?,
      currentTemperature:
          (json['currentTemperature'] as num?)?.toDouble(),
      currentWeatherDescription:
          json['currentWeatherDescription'] as String?,
      generatedAt: DateTime.tryParse('${json['generatedAt']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ScheduleDetail extends ScheduleSummary {
  ScheduleDetail({
    required super.id,
    required super.title,
    required super.totalDays,
    required super.budgetInput,
    required super.preferenceInput,
    required super.userLocationName,
    required super.currentTemperature,
    required super.currentWeatherDescription,
    required super.generatedAt,
    required this.destinations,
  });

  final List<ScheduleDestination> destinations;

  factory ScheduleDetail.fromJson(Map<String, dynamic> json) {
    return ScheduleDetail(
      id: '${json['id']}',
      title: json['title'] as String? ?? 'Untitled trip',
      totalDays: json['totalDays'] as int? ?? 1,
      budgetInput: (json['budgetInput'] as num?)?.toDouble() ?? 0,
      preferenceInput: json['preferenceInput'] as String?,
      userLocationName: json['userLocationName'] as String?,
      currentTemperature:
          (json['currentTemperature'] as num?)?.toDouble(),
      currentWeatherDescription:
          json['currentWeatherDescription'] as String?,
      generatedAt: DateTime.tryParse('${json['generatedAt']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      destinations: (json['destinations'] as List? ?? [])
          .map((e) => ScheduleDestination.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ScheduleDestination {
  ScheduleDestination({
    required this.id,
    required this.destinationId,
    required this.destinationName,
    required this.province,
    required this.imageUrl,
    required this.dayNumber,
    required this.orderInDay,
    required this.note,
    required this.estimatedTime,
  });

  final String id;
  final String destinationId;
  final String destinationName;
  final String province;
  final String? imageUrl;
  final int dayNumber;
  final int orderInDay;
  final String? note;
  final String? estimatedTime;

  factory ScheduleDestination.fromJson(Map<String, dynamic> json) {
    return ScheduleDestination(
      id: '${json['id']}',
      destinationId: '${json['destinationId']}',
      destinationName: json['destinationName'] as String? ?? '',
      province: json['province'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      dayNumber: json['dayNumber'] as int? ?? 1,
      orderInDay: json['orderInDay'] as int? ?? 1,
      note: json['note'] as String?,
      estimatedTime: json['estimatedTime'] as String?,
    );
  }
}

class Comment {
  Comment({
    required this.id,
    required this.destinationId,
    required this.userId,
    required this.username,
    required this.fullName,
    required this.rating,
    required this.content,
    required this.isApproved,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String destinationId;
  final String userId;
  final String username;
  final String fullName;
  final int rating;
  final String? content;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: '${json['id']}',
      destinationId: '${json['destinationId']}',
      userId: '${json['userId']}',
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      content: json['content'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
      createdAt: DateTime.tryParse('${json['createdAt']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse('${json['updatedAt']}'),
    );
  }
}

class FavoriteDestination {
  FavoriteDestination({
    required this.id,
    required this.savedAt,
    required this.destination,
  });

  final String id;
  final DateTime savedAt;
  final Destination destination;

  factory FavoriteDestination.fromJson(Map<String, dynamic> json) {
    return FavoriteDestination(
      id: '${json['id']}',
      savedAt: DateTime.tryParse('${json['savedAt']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      destination: Destination.fromApi(
        json['destination'] as Map<String, dynamic>,
      ).copyWith(isFavorite: true),
    );
  }
}
