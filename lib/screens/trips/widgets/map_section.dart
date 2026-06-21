import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapSection extends StatefulWidget {
  final LatLng? destination; // Nhận tọa độ từ kết quả search của màn hình cha

  const MapSection({super.key, this.destination});

  @override
  State<MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<MapSection> {
  late GoogleMapController mapController;
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final String googleApiKey = "AIzaSyC-sZpjiTqOpPHQ0D3KuavSgKOHm9KPPjA";

  @override
  void initState() {
    super.initState();
    _determinePosition(); // Lấy vị trí ngay khi mở app
  }

  // Lấy vị trí hiện tại của User
  Future<void> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _markers.add(Marker(markerId: const MarkerId('me'), position: _currentPosition!));
    });
  }

  // Vẽ đường từ Vị trí hiện tại đến Điểm search
  Future<void> _getRoute(LatLng dest) async {
    if (_currentPosition == null) return;

    final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&destination=${dest.latitude},${dest.longitude}&key=$googleApiKey';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['routes'].isNotEmpty) {
      final points = data['routes'][0]['overview_polyline']['points'];
      setState(() {
        _markers.add(Marker(markerId: const MarkerId('dest'), position: dest));
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: _decodePolyline(points),
          color: const Color(0xFF2ECC71),
          width: 5,
        ));
      });
      // Zoom map để thấy cả 2 điểm
      mapController.animateCamera(CameraUpdate.newLatLngBounds(
          _getBounds(_currentPosition!, dest), 100
      ));
    }
  }

  @override
  void didUpdateWidget(MapSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.destination != null) _getRoute(widget.destination!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _currentPosition == null
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
          initialCameraPosition: CameraPosition(target: _currentPosition!, zoom: 14),
          onMapCreated: (c) => mapController = c,
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
        ),
      ),
    );
  }

  // Hàm phụ trợ để tính toán zoom map
  LatLngBounds _getBounds(LatLng start, LatLng end) {
    return LatLngBounds(
      southwest: LatLng(start.latitude < end.latitude ? start.latitude : end.latitude, start.longitude < end.longitude ? start.longitude : end.longitude),
      northeast: LatLng(start.latitude > end.latitude ? start.latitude : end.latitude, start.longitude > end.longitude ? start.longitude : end.longitude),
    );
  }

  // Hàm giải mã tọa độ từ Google Directions API
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do { b = encoded.codeUnitAt(index++) - 63; result |= (b & 0x1f) << shift; shift += 5; } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1)); lat += dlat;
      shift = 0; result = 0;
      do { b = encoded.codeUnitAt(index++) - 63; result |= (b & 0x1f) << shift; shift += 5; } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1)); lng += dlng;
      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }
}