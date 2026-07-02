// ignore_for_file: use_string_in_part_of_directives
part of api_client;

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

  // ─── Auth ──────────────────────────────────────────────────────────────────
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

  Future<AuthUser> fetchProfile() async {
    final res = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/me'),
      headers: _headers,
    );
    return AuthUser.fromJson(await _decode(res));
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

  // ─── Destinations ──────────────────────────────────────────────────────────
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

  // ─── Comments ──────────────────────────────────────────────────────────────
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

  // ─── Favorites ─────────────────────────────────────────────────────────────
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

  // ─── Schedules ─────────────────────────────────────────────────────────────
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
}
