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
    stops.add(_Stop(label.isEmpty ? 'Diem ${i + 1}' : label, LatLng(base.latitude, base.longitude)));
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
  if (value.contains('ha long') || value.contains('halong')) return const _Coordinate(20.9101, 107.1839);
  if (value.contains('ninh binh')) return const _Coordinate(20.2506, 105.9745);
  if (value.contains('can tho')) return const _Coordinate(10.0452, 105.7469);
  if (value.contains('vung tau')) return const _Coordinate(10.4114, 107.1362);
  if (value.contains('quy nhon')) return const _Coordinate(13.7565, 109.2217);
  if (value.contains('mui ne') || value.contains('phan thiet')) return const _Coordinate(10.9281, 108.1121);
  if (value.contains('bien hoa')) return const _Coordinate(10.9574, 106.8429);
  if (value.contains('tam dao')) return const _Coordinate(21.4500, 105.6500);
  if (value.contains('cuc phuong')) return const _Coordinate(20.2500, 105.6000);
  if (value.contains('ba vi')) return const _Coordinate(21.0833, 105.3333);
  if (value.contains('cat ba')) return const _Coordinate(20.7269, 107.0498);
  if (value.contains('tuy hoa')) return const _Coordinate(13.0956, 109.2994);
  if (value.contains('cam ranh')) return const _Coordinate(11.5615, 109.1480);
  if (value.contains('phan rang')) return const _Coordinate(11.5642, 108.9886);
  if (value.contains('long hai')) return const _Coordinate(10.4333, 107.2333);
  if (value.contains('binh chau')) return const _Coordinate(10.5667, 107.5667);
  if (value.contains('tay ninh')) return const _Coordinate(11.3229, 106.0982);
  if (value.contains('cao bang')) return const _Coordinate(22.6667, 106.2500);
  if (value.contains('ha giang')) return const _Coordinate(22.8233, 104.9836);
  if (value.contains('mai chau')) return const _Coordinate(20.6667, 105.0833);
  if (value.contains('bac ha')) return const _Coordinate(22.5381, 104.2936);
  if (value.contains('lang son')) return const _Coordinate(21.8478, 106.7575);
  if (value.contains('mong cai')) return const _Coordinate(21.5333, 107.9667);
  if (value.contains('thanh hoa')) return const _Coordinate(19.8067, 105.7853);
  if (value.contains('vinh')) return const _Coordinate(18.6733, 105.6811);
  if (value.contains('hai phong')) return const _Coordinate(20.8597, 106.6826);
  if (value.contains('rach gia')) return const _Coordinate(10.0126, 105.0809);
  if (value.contains('ha tien')) return const _Coordinate(10.3833, 104.4833);
  return const _Coordinate(16.0544, 108.2022);
}

String _formatMoney(num value) {
  final rounded = value.round();
  final text = rounded.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      );
  return rounded <= 0 ? '0đ' : '$text đ';
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



