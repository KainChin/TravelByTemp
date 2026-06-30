// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

List<_Stop> _stopsFor(Object? day) {
  final activities = _activitiesFor(day);
  final stops = <_Stop>[];
  for (var i = 0; i < activities.length; i++) {
    final label = '${activities[i]['destination'] ?? _activityTitle(activities[i])}'.trim();
    final lat = _numValue(activities[i]['latitude'] ?? activities[i]['lat']);
    final lng = _numValue(activities[i]['longitude'] ?? activities[i]['lng']);
    final base = lat != null && lng != null ? _Coordinate(lat, lng) : _coordinateFor(label);
    stops.add(_Stop(label.isEmpty ? 'Diem ${i + 1}' : label, LatLng(base.latitude + i * 0.008, base.longitude + i * 0.01)));
  }
  return stops;
}

double? _numValue(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

_Coordinate _coordinateFor(String label) {
  final value = label.toLowerCase();
  if (value.contains('ha noi') || value.contains('hanoi')) return const _Coordinate(21.0285, 105.8542);
  if (value.contains('da nang') || value.contains('nang')) return const _Coordinate(16.0544, 108.2022);
  if (value.contains('hoi an')) return const _Coordinate(15.8801, 108.3380);
  if (value.contains('hue')) return const _Coordinate(16.4637, 107.5909);
  if (value.contains('nha trang')) return const _Coordinate(12.2388, 109.1967);
  if (value.contains('da lat') || value.contains('lat')) return const _Coordinate(11.9404, 108.4583);
  if (value.contains('phu quoc')) return const _Coordinate(10.2899, 103.9840);
  if (value.contains('sapa') || value.contains('sa pa')) return const _Coordinate(22.3364, 103.8438);
  return const _Coordinate(16.0544, 108.2022);
}

String _formatMoney(num value) {
  final rounded = value.round();
  if (rounded <= 0) return '0d';
  final text = rounded.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      );
  return '${text}d';
}

class _Stop {
  const _Stop(this.label, this.point);
  final String label;
  final LatLng point;
}

class _Coordinate {
  const _Coordinate(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}



