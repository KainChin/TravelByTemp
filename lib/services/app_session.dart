import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assignment/models/auth_session.dart';
import 'package:assignment/services/api_client.dart';

class AppSession extends ChangeNotifier {
  AppSession() : api = ApiClient();

  final ApiClient api;
  AuthSession? auth;
  AiRecommendResult? lastAiResult;

  double latitude = 10.7769;
  double longitude = 106.7009;
  String locationName = 'Thu Duc, Sai Gon';
  double userTemperatureC = 32;
  String weatherDescription = 'Đang tải...';

  bool get isLoggedIn => auth != null;

  static const _tokenKey = 'vietai_token';
  static const _userKey = 'vietai_user';

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (token != null && userJson != null) {
      api.setToken(token);
      auth = AuthSession(
        accessToken: token,
        user: AuthUser.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>,
        ),
      );
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    final session = await api.login(username, password);
    auth = session;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.accessToken);
    await prefs.setString(_userKey, jsonEncode({
      'id': session.user.id,
      'username': session.user.username,
      'email': session.user.email,
      'fullName': session.user.fullName,
      'role': session.user.role,
    }));
    notifyListeners();
    await refreshLocationAndWeather();
  }

  Future<void> logout() async {
    auth = null;
    lastAiResult = null;
    api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    notifyListeners();
  }

  Future<void> refreshLocationAndWeather() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        await _loadWeather();
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      latitude = pos.latitude;
      longitude = pos.longitude;
      locationName = 'Vị trí hiện tại';
      await _loadWeather();
    } catch (_) {
      await _loadWeather();
    }
  }

  Future<void> _loadWeather() async {
    try {
      final w = await api.fetchWeather(latitude, longitude);
      userTemperatureC = w.temperatureC;
      weatherDescription = w.description;
      notifyListeners();
    } catch (_) {
      weatherDescription = 'Không lấy được thời tiết';
      notifyListeners();
    }
  }

  Future<AiRecommendResult> generateItinerary({
    required double budget,
    required int days,
    required String preferences,
  }) async {
    final result = await api.recommend(
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      budgetInput: budget,
      totalDays: days,
      preferenceInput: preferences,
    );
    lastAiResult = result;
    userTemperatureC = result.currentTemperature;
    weatherDescription = result.currentWeatherDescription;
    notifyListeners();
    return result;
  }
}
