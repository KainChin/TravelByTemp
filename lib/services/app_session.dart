import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assignment/models/auth_session.dart';
import 'package:assignment/services/api_client.dart';

class AppSession extends ChangeNotifier {
  AppSession() : api = ApiClient();

  final ApiClient api;
  AuthSession? auth;
  AiRecommendResult? lastAiResult;
  List<ScheduleSummary> schedules = [];
  bool schedulesLoading = false;
  String? schedulesError;

  double latitude = 10.7769;
  double longitude = 106.7009;
  String locationName = 'Thu Duc, Sai Gon';
  double userTemperatureC = 32;
  String weatherDescription = 'Đang tải...';

  bool get isLoggedIn => auth != null;

  static const _tokenKey = 'vietai_token';
  static const _refreshTokenKey = 'vietai_refresh_token';
  static const _expiresAtKey = 'vietai_expires_at';
  static const _userKey = 'vietai_user';

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final expiresAtText = prefs.getString(_expiresAtKey);
    final userJson = prefs.getString(_userKey);

    if (token == null || userJson == null || expiresAtText == null) {
      await _clearStoredAuth(prefs);
      return;
    }

    try {
      final expiresAt = DateTime.tryParse(expiresAtText);
      if (expiresAt == null || !expiresAt.isAfter(DateTime.now())) {
        await _clearStoredAuth(prefs);
        return;
      }

      api.setToken(token);
      auth = AuthSession(
        accessToken: token,
        refreshToken: prefs.getString(_refreshTokenKey) ?? '',
        expiresAt: expiresAt,
        user: AuthUser.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>,
        ),
      );
      notifyListeners();
      await loadSchedules();
    } catch (_) {
      await _clearStoredAuth(prefs);
    }
  }

  Future<void> login(String username, String password) async {
    final session = await api.login(username, password);
    await _applyAuthSession(session);
    await refreshLocationAndWeather();
    await loadSchedules();
  }

  Future<void> register({
    required String username,
    String? email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final session = await api.register(
      username: username,
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
    await _applyAuthSession(session);
    await refreshLocationAndWeather();
    await loadSchedules();
  }

  Future<BeginRegisterResult> beginRegister({
    required String username,
    String? email,
    required String password,
    required String fullName,
    String? phone,
  }) {
    return api.beginRegister(
      username: username,
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
  }

  Future<void> verifyRegister({
    required String verificationId,
    required String code,
  }) async {
    final session = await api.verifyRegister(
      verificationId: verificationId,
      code: code,
    );
    await _applyAuthSession(session);
    await refreshLocationAndWeather();
    await loadSchedules();
  }

  Future<void> resetPassword({
    required String usernameOrEmail,
    required String newPassword,
  }) {
    return api.resetPassword(
      usernameOrEmail: usernameOrEmail,
      newPassword: newPassword,
    );
  }

  Future<void> _applyAuthSession(AuthSession session) async {
    auth = session;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.accessToken);
    await prefs.setString(_refreshTokenKey, session.refreshToken);
    await prefs.setString(_expiresAtKey, session.expiresAt.toIso8601String());
    await _saveUser(prefs, session.user);
    notifyListeners();
  }

  Future<void> logout() async {
    auth = null;
    lastAiResult = null;
    schedules = [];
    schedulesError = null;
    api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await _clearStoredAuth(prefs);
    notifyListeners();
  }

  Future<void> _clearStoredAuth(SharedPreferences prefs) async {
    auth = null;
    api.setToken(null);
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_expiresAtKey);
    await prefs.remove(_userKey);
  }

  Future<void> refreshAuth() async {
    final current = auth;
    if (current == null || current.refreshToken.isEmpty) return;

    final next = await api.refresh(current.refreshToken);
    auth = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, next.accessToken);
    await prefs.setString(_refreshTokenKey, next.refreshToken);
    await prefs.setString(_expiresAtKey, next.expiresAt.toIso8601String());
    await _saveUser(prefs, next.user);
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final current = auth;
    if (current == null) return;

    final user = await api.fetchProfile();
    auth = AuthSession(
      accessToken: current.accessToken,
      refreshToken: current.refreshToken,
      expiresAt: current.expiresAt,
      user: user,
    );

    final prefs = await SharedPreferences.getInstance();
    await _saveUser(prefs, user);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String username,
    required String email,
    required String fullName,
    String? bio,
    String? phone,
    String? avatarUrl,
  }) async {
    final current = auth;
    if (current == null) return;

    final user = await api.updateProfile(
      username: username,
      email: email,
      fullName: fullName,
      bio: bio,
      phone: phone,
      avatarUrl: avatarUrl,
    );
    auth = AuthSession(
      accessToken: current.accessToken,
      refreshToken: current.refreshToken,
      expiresAt: current.expiresAt,
      user: user,
    );

    final prefs = await SharedPreferences.getInstance();
    await _saveUser(prefs, user);
    notifyListeners();
  }

  Future<void> _saveUser(SharedPreferences prefs, AuthUser user) {
    return prefs.setString(_userKey, jsonEncode({
      'id': user.id,
      'username': user.username,
      'email': user.email,
      'fullName': user.fullName,
      'role': user.role,
      'bio': user.bio,
      'phone': user.phone,
      'avatarUrl': user.avatarUrl,
    }));
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
      
      try {
        final placemarks = await placemarkFromCoordinates(latitude, longitude)
            .timeout(const Duration(seconds: 4));
        if (placemarks.isNotEmpty) {
          final pm = placemarks.first;
          final district = pm.subAdministrativeArea ?? pm.subLocality ?? pm.locality ?? '';
          final city = pm.administrativeArea ?? '';
          
          final List<String> parts = [];
          if (district.isNotEmpty) parts.add(district);
          if (city.isNotEmpty && city != district) parts.add(city);
          
          if (parts.isNotEmpty) {
            locationName = parts.join(', ');
          } else {
            locationName = 'Hồ Chí Minh, Việt Nam';
          }
        } else {
          locationName = 'Hồ Chí Minh, Việt Nam';
        }
      } catch (_) {
        locationName = 'Thủ Đức, Hồ Chí Minh';
      }
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
    await loadSchedules();
    return result;
  }

  Future<void> loadSchedules() async {
    if (auth == null || schedulesLoading) return;

    schedulesLoading = true;
    schedulesError = null;
    notifyListeners();

    try {
      schedules = await api.fetchSchedules();
    } catch (e) {
      schedulesError = e.toString();
    } finally {
      schedulesLoading = false;
      notifyListeners();
    }
  }
}
