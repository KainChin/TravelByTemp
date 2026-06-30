// ignore_for_file: use_string_in_part_of_directives

part of route_analysis;

const _domesticFlightFareVnd = <String, double>{
  'da_nang|ho_chi_minh': 1800000,
  'da_nang|phu_quoc': 2800000,
  'ha_noi|ho_chi_minh': 2500000,
  'ha_noi|phu_quoc': 3200000,
  'ho_chi_minh|phu_quoc': 2200000,
};

double _flightFareEstimateVnd(String fromName, String toName, double distanceKm) {
  final from = _flightFarePlaceKey(fromName);
  final to = _flightFarePlaceKey(toName);
  final fare = _domesticFlightFareVnd[_routeFareKey(from, to)];
  if (fare != null) return fare;

  if (distanceKm < 300) return 1200000;
  if (distanceKm < 700) return 1800000;
  if (distanceKm < 1200) return 2500000;
  return 3500000;
}

String _routeFareKey(String a, String b) {
  final items = [a, b]..sort();
  return '${items[0]}|${items[1]}';
}

String _flightFarePlaceKey(String value) {
  final normalized = _normalizeFareText(value);
  if (normalized.contains('tan son nhat') ||
      normalized.contains('ho chi minh') ||
      normalized.contains('tp.hcm') ||
      normalized.contains('sai gon')) {
    return 'ho_chi_minh';
  }
  if (normalized.contains('noi bai') || normalized.contains('ha noi')) {
    return 'ha_noi';
  }
  if (normalized.contains('da nang')) return 'da_nang';
  if (normalized.contains('phu quoc')) return 'phu_quoc';
  if (normalized.contains('con dao')) return 'con_dao';
  if (normalized.contains('can tho')) return 'can_tho';
  if (normalized.contains('nha trang') || normalized.contains('cam ranh')) {
    return 'nha_trang';
  }
  if (normalized.contains('da lat') || normalized.contains('lien khuong')) {
    return 'da_lat';
  }
  return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '');
}

String _normalizeFareText(String value) {
  return value.toLowerCase()
      .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd');
}



