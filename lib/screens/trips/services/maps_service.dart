import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/trip_models.dart';

class MapsService {
  static const _apiKey = 'AIzaSyC-sZpjiTqOpPHQ0D3KuavSgKOHm9KPPjA';
  static const _baseUrl = 'https://maps.googleapis.com/maps/api';

  // ── Autocomplete tìm địa điểm ─────────────────────────────
  static Future<List<Map<String, String>>> searchPlaces(String query) async {
    if (query.isEmpty) return [];
    final url = '$_baseUrl/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&language=vi'
        '&components=country:vn'
        '&key=$_apiKey';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return [];

    final data = json.decode(res.body);
    final predictions = data['predictions'] as List;
    return predictions.map<Map<String, String>>((p) => {
      'placeId': p['place_id'] as String,
      'name': p['structured_formatting']['main_text'] as String,
      'address': p['description'] as String,
    }).toList();
  }

  // ── Lấy tọa độ từ placeId ─────────────────────────────────
  static Future<LatLng?> getPlaceLatLng(String placeId) async {
    final url = '$_baseUrl/place/details/json'
        '?place_id=$placeId'
        '&fields=geometry'
        '&key=$_apiKey';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return null;

    final data = json.decode(res.body);
    final loc = data['result']['geometry']['location'];
    return LatLng(loc['lat'] as double, loc['lng'] as double);
  }

  // ── Tính khoảng cách & thời gian ─────────────────────────
  static Future<TripDestination?> getDirections({
    required LatLng origin,
    required TripDestination destination,
  }) async {
    final url = '$_baseUrl/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.lat},${destination.lng}'
        '&language=vi'
        '&key=$_apiKey';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return null;

    final data = json.decode(res.body);
    final routes = data['routes'] as List;
    if (routes.isEmpty) return null;

    final leg = routes[0]['legs'][0];
    final distance = leg['distance']['text'] as String;
    final duration = leg['duration']['text'] as String;
    final routeName = routes[0]['summary'] as String;

    return destination.copyWith(
      distanceText: distance,
      durationText: duration,
      bestRoute: routeName.isNotEmpty ? 'Tuyến tốt nhất: $routeName' : null,
    );
  }

  // ── Lấy polyline points ───────────────────────────────────
  static Future<List<LatLng>> getPolylinePoints({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final url = '$_baseUrl/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$_apiKey';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return [];

    final data = json.decode(res.body);
    final routes = data['routes'] as List;
    if (routes.isEmpty) return [];

    final points = routes[0]['overview_polyline']['points'] as String;
    return _decodePolyline(points);
  }

  // ── Decode polyline ───────────────────────────────────────
  static List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0, lng = 0;

    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}