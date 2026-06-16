import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/trip_models.dart';
import '../services/maps_service.dart';

class TripProvider extends ChangeNotifier {
  LatLng? currentLocation;
  TripDestination? destination;
  List<LatLng> polylinePoints = [];
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<Map<String, String>> suggestions = [];
  bool isLoading = false;
  bool isSearching = false;
  String? errorMessage;

  // ── Lấy vị trí hiện tại ───────────────────────────────────
  Future<void> getCurrentLocation() async {
    isLoading = true;
    notifyListeners();

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        errorMessage = 'Vui lòng cấp quyền truy cập vị trí';
        isLoading = false;
        notifyListeners();
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      currentLocation = LatLng(pos.latitude, pos.longitude);
      _updateCurrentMarker();
    } catch (e) {
      // fallback: Ho Chi Minh City
      currentLocation = const LatLng(10.7769, 106.7009);
      _updateCurrentMarker();
    }

    isLoading = false;
    notifyListeners();
  }

  // ── Tìm kiếm địa điểm ────────────────────────────────────
  Future<void> searchPlaces(String query) async {
    if (query.length < 2) {
      suggestions = [];
      notifyListeners();
      return;
    }
    isSearching = true;
    notifyListeners();

    suggestions = await MapsService.searchPlaces(query);
    isSearching = false;
    notifyListeners();
  }

  // ── Chọn địa điểm từ gợi ý ───────────────────────────────
  Future<void> selectDestination(Map<String, String> place) async {
    suggestions = [];
    isLoading = true;
    notifyListeners();

    final latLng = await MapsService.getPlaceLatLng(place['placeId']!);
    if (latLng == null || currentLocation == null) {
      isLoading = false;
      notifyListeners();
      return;
    }

    var dest = TripDestination(
      name: place['name']!,
      address: place['address']!,
      lat: latLng.latitude,
      lng: latLng.longitude,
    );

    // Lấy khoảng cách + thời gian
    final result = await MapsService.getDirections(
      origin: currentLocation!,
      destination: dest,
    );
    destination = result ?? dest;

    // Lấy đường đi
    polylinePoints = await MapsService.getPolylinePoints(
      origin: currentLocation!,
      destination: latLng,
    );

    _updateMapElements(latLng);
    isLoading = false;
    notifyListeners();
  }

  // ── Xóa điểm đến ─────────────────────────────────────────
  void clearDestination() {
    destination = null;
    polylinePoints = [];
    polylines = {};
    markers = {};
    _updateCurrentMarker();
    notifyListeners();
  }

  // ── Update markers & polyline ─────────────────────────────
  void _updateMapElements(LatLng destLatLng) {
    markers = {
      Marker(
        markerId: const MarkerId('current'),
        position: currentLocation!,
        infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: destLatLng,
        infoWindow: InfoWindow(title: destination?.name ?? ''),
      ),
    };

    if (polylinePoints.isNotEmpty) {
      polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: const Color(0xFF2ECC71),
          width: 4,
        ),
      };
    }
  }

  void _updateCurrentMarker() {
    if (currentLocation == null) return;
    markers = {
      Marker(
        markerId: const MarkerId('current'),
        position: currentLocation!,
        infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
      ),
    };
  }
}
