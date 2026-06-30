// ignore_for_file: use_string_in_part_of_directives

part of route_analysis;

class TripRouteAnalysis {
  const TripRouteAnalysis({
    this.routeId,
    required this.departure,
    required this.destinations,
    required this.legs,
  });

  final String? routeId;
  final Destination departure;
  final List<SelectedDestination> destinations;
  final List<RouteLeg> legs;

  TripRouteAnalysis copyWith({
    String? routeId,
    Destination? departure,
    List<SelectedDestination>? destinations,
    List<RouteLeg>? legs,
  }) {
    return TripRouteAnalysis(
      routeId: routeId ?? this.routeId,
      departure: departure ?? this.departure,
      destinations: destinations ?? this.destinations,
      legs: legs ?? this.legs,
    );
  }

  bool get hasFlightLeg => legs.any((leg) => leg.usesFlight);
  bool get hasFerryLeg => legs.any((leg) => leg.recommendedMode == TransportMode.ferry);
  bool get isConstraintOptimalRoute => legs.isNotEmpty && !legs.any(_isInvalidLeg);
  double get totalDistanceKm => legs.fold(0, (sum, leg) => sum + leg.distanceKm);
  double get optimizedHours => legs.fold(0, (sum, leg) => sum + leg.recommendedHours);
  double get estimatedRouteCostVnd =>
      legs.fold(0, (sum, leg) => sum + leg.estimatedCostVnd);
  double budgetUsagePercent(double budgetVnd) {
    if (budgetVnd <= 0) return 0;
    return estimatedRouteCostVnd / budgetVnd * 100;
  }

  int get transferCount {
    if (legs.length <= 1) return 0;
    var count = 0;
    for (var i = 1; i < legs.length; i++) {
      if (legs[i].recommendedMode != legs[i - 1].recommendedMode) count++;
    }
    return count;
  }

  bool get needsTransportChange => transferCount > 0;

  String get convenienceLevel {
    if (legs.length >= 4 || transferCount >= 3) return 'Phức tạp';
    if (legs.length == 3 || transferCount == 2) return 'Trung bình';
    return 'Thuận tiện';
  }

  String get convenienceBadge {
    switch (convenienceLevel) {
      case 'Thuận tiện':
        return '🟢 Độ thuận tiện: Thuận tiện';
      case 'Trung bình':
        return '🟡 Độ thuận tiện: Trung bình';
      default:
        return '🔴 Độ thuận tiện: Phức tạp';
    }
  }

  String get routeStrategy {
    final hasLongFlight = legs.any(
      (leg) => leg.recommendedMode == TransportMode.flight && leg.distanceKm > 500,
    );
    final roadOnly = legs.every(
      (leg) =>
          leg.recommendedMode == TransportMode.motorbike ||
          leg.recommendedMode == TransportMode.car ||
          leg.recommendedMode == TransportMode.coach,
    );
    if (hasLongFlight && optimizedHours <= 8) return '🚀 Nhanh nhất';
    if (roadOnly && estimatedRouteCostVnd < 900000) return '💰 Tiết kiệm nhất';
    return '⚖️ Cân bằng giữa thời gian và chi phí';
  }

  List<String> get aiBadges => [
        if (isConstraintOptimalRoute) '⭐ AI đề xuất',
        routeStrategy,
        convenienceBadge,
      ];

  List<String> get importantNotes {
    final notes = <String>[];
    if (hasFlightLeg) notes.add('Nên đặt vé máy bay trước 7-14 ngày.');
    if (hasFerryLeg) {
      notes.add('Cần đổi phương tiện tại bến cảng và kiểm tra lịch tàu/phà.');
    }
    if (optimizedHours >= 8) {
      notes.add('Chuyến đi khá dài, nên có thời gian nghỉ giữa đường.');
    }
    if (legs.any((leg) => leg.recommendedMode == TransportMode.coach && leg.distanceKm > 250)) {
      notes.add('Chặng đường bộ dài có thể bị ảnh hưởng bởi ùn tắc.');
    }
    return notes.take(3).toList();
  }

  String get aiRecommendation {
    final sentences = <String>[];
    sentences.add(
      isConstraintOptimalRoute
          ? 'Tuyến này được chọn vì các chặng đều hợp lệ với điều kiện địa lý và phương tiện hiện có.'
          : 'Tuyến này cần kiểm tra lại vì còn thiếu dữ liệu xác minh phương tiện.',
    );
    if (hasFlightLeg) {
      sentences.add('Ưu điểm lớn nhất là rút ngắn thời gian bằng chặng bay.');
    } else if (hasFerryLeg) {
      sentences.add('Ưu điểm lớn nhất là giữ chi phí hợp lý bằng tuyến cảng và tàu/phà.');
    } else if (convenienceLevel == 'Thuận tiện') {
      sentences.add('Ưu điểm lớn nhất là ít chặng và ít chuyển phương tiện.');
    } else {
      sentences.add('Ưu điểm lớn nhất là cân bằng giữa thời gian và chi phí.');
    }
    if (needsTransportChange) {
      sentences.add('Có trung chuyển, nên chừa thời gian nối chuyến giữa các chặng.');
    }
    return sentences.take(3).join(' ');
  }

  String get routeTitle {
    final names = [departure.name, ...destinations.map((e) => e.destination.name)];
    return names.join(' -> ');
  }

  static TripRouteAnalysis from({
    required String departurePoint,
    required List<SelectedDestination> selectedDestinations,
    Destination? departure,
    double? budgetPerPerson,
  }) {
    final start = departure ?? DestinationCatalog.hoChiMinh.copyWithName(departurePoint);

    final legs = <RouteLeg>[];
    var current = start;
    var currentName = start.name;
    var order = 1;
    for (var i = 0; i < selectedDestinations.length; i++) {
      final to = selectedDestinations[i].destination;
      final expanded = _buildFeasibleLegs(
        orderStart: order,
        from: current,
        fromName: currentName,
        to: to,
        budgetPerPerson: budgetPerPerson,
      );
      legs.addAll(expanded);
      order += expanded.length;
      current = to;
      currentName = to.name;
    }

    final normalized = selectedDestinations.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final leg = _lastLegTo(legs, item.destination.id);
      return SelectedDestination(
        destination: item.destination,
        fromLabel: leg?.fromName ?? (index == 0 ? start.name : selectedDestinations[index - 1].destination.name),
        distanceKm: leg?.distanceKm ?? 0,
        startDate: item.startDate,
        endDate: item.endDate,
      );
    }).toList();

    return TripRouteAnalysis(
      routeId: null,
      departure: start,
      destinations: normalized,
      legs: legs,
    );
  }

  factory TripRouteAnalysis.fromApi(
    Map<String, dynamic> json, {
    double? budgetPerPerson,
  }) {
    final departureJson = json['departure'] as Map<String, dynamic>;
    final destinationJson = json['destinations'] as List? ?? const [];
    final legJson = json['legs'] as List? ?? const [];
    final departure = _placeFromJson(departureJson);
    final destinations = destinationJson
        .whereType<Map<String, dynamic>>()
        .map(_placeFromJson)
        .toList();
    final apiLegs = legJson.whereType<Map<String, dynamic>>().map((item) {
      return RouteLeg(
        order: item['order'] as int? ?? 1,
        fromName: item['fromName'] as String? ?? '',
        to: _placeFromJson(item['to'] as Map<String, dynamic>),
        distanceKm: (item['distanceKm'] as num?)?.toDouble() ?? 0,
        recommendedMode: _modeFromApi(item['recommendedMode'] as String?),
        reason: item['reason'] as String? ?? '',
        isGoogleEstimate: item['isGoogleEstimate'] as bool? ?? false,
      );
    }).toList();
    final legs = _needsRouteRepair(departure, destinations, apiLegs)
        ? _buildVerifiedLegs(departure, destinations, budgetPerPerson: budgetPerPerson)
        : apiLegs;

    return TripRouteAnalysis(
      routeId: json['routeId'] as String?,
      departure: departure,
      destinations: destinations.asMap().entries.map((entry) {
        final leg = _lastLegTo(legs, entry.value.id);
        return SelectedDestination(
          destination: entry.value,
          fromLabel: leg?.fromName ?? departure.name,
          distanceKm: leg?.distanceKm ?? 0,
        );
      }).toList(),
      legs: legs,
    );
  }

  static Destination _placeFromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      region: json['region'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  static TransportMode _modeFromApi(String? value) {
    switch (value) {
      case 'motorbike':
        return TransportMode.motorbike;
      case 'car':
        return TransportMode.car;
      case 'coach':
        return TransportMode.coach;
      case 'train':
        return TransportMode.train;
      case 'ferry':
        return TransportMode.ferry;
      case 'flight':
        return TransportMode.flight;
      default:
        return TransportMode.car;
    }
  }

  static double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const radius = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return radius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double degree) => degree * pi / 180;

  static RouteLeg? _lastLegTo(List<RouteLeg> legs, String destinationId) {
    for (var i = legs.length - 1; i >= 0; i--) {
      if (legs[i].to.id == destinationId) return legs[i];
    }
    return null;
  }

  static bool _needsRouteRepair(
    Destination departure,
    List<Destination> destinations,
    List<RouteLeg> legs,
  ) {
    if (legs.isEmpty) return destinations.isNotEmpty;
    for (final leg in legs) {
      final toIsland = _isIsland(leg.to);
      final forbiddenIslandMode = leg.recommendedMode == TransportMode.motorbike ||
          leg.recommendedMode == TransportMode.car ||
          leg.recommendedMode == TransportMode.coach ||
          leg.recommendedMode == TransportMode.train;
      if (toIsland && forbiddenIslandMode) return true;
      if (leg.recommendedMode == TransportMode.train && !_hasRail(leg.to)) return true;
    }

    var current = departure;
    for (final destination in destinations) {
      if (_isIsland(destination) && !_hasDirectIslandFlight(current, destination)) {
        final hasFerryToIsland = legs.any(
          (leg) =>
              leg.to.id == destination.id &&
              leg.recommendedMode == TransportMode.ferry,
        );
        if (!hasFerryToIsland) return true;
      }
      current = destination;
    }

    return false;
  }

  static bool _isInvalidLeg(RouteLeg leg) {
    final toIsland = _isIsland(leg.to);
    final forbiddenIslandMode = leg.recommendedMode == TransportMode.motorbike ||
        leg.recommendedMode == TransportMode.car ||
        leg.recommendedMode == TransportMode.coach ||
        leg.recommendedMode == TransportMode.train;
    if (toIsland && forbiddenIslandMode) return true;
    if (leg.recommendedMode == TransportMode.train && !_hasRail(leg.to)) return true;
    if (leg.recommendedMode == TransportMode.flight && !_hasAirport(leg.to)) return true;
    return false;
  }

  static List<RouteLeg> _buildVerifiedLegs(
    Destination departure,
    List<Destination> destinations, {
    double? budgetPerPerson,
  }) {
    final legs = <RouteLeg>[];
    var current = departure;
    var currentName = departure.name;
    var order = 1;
    for (final destination in destinations) {
      final expanded = _buildFeasibleLegs(
        orderStart: order,
        from: current,
        fromName: currentName,
        to: destination,
        budgetPerPerson: budgetPerPerson,
      );
      legs.addAll(expanded);
      order += expanded.length;
      current = destination;
      currentName = destination.name;
    }
    return legs;
  }

  static List<RouteLeg> _buildFeasibleLegs({
    required int orderStart,
    required Destination from,
    required String fromName,
    required Destination to,
    double? budgetPerPerson,
  }) {
    final fromIsland = _isIsland(from);
    final toIsland = _isIsland(to);
    if (!fromIsland && toIsland) {
      if (_hasDirectIslandFlight(from, to)) {
        return [
          _manualLeg(orderStart, fromName, from, to, TransportMode.flight,
              'Hai điểm có tuyến bay phù hợp, máy bay là phương án khả thi và nhanh nhất.'),
        ];
      }
      if (_prefersFastIslandRoute(budgetPerPerson) && _hasAirport(to)) {
        final airport = _nearestAirportForIslandRoute(from, to);
        return [
          _autoLeg(orderStart, fromName, from, airport),
          _manualLeg(orderStart + 1, airport.name, airport, to, TransportMode.flight,
              'Điểm đến là đảo, đi qua sân bay gần nhất rồi bay để tiết kiệm thời gian.'),
        ];
      }
      final port = _mainlandPortForIsland(to);
      return [
        _autoLeg(orderStart, fromName, from, port),
        _manualLeg(orderStart + 1, port.name, port, to, TransportMode.ferry, 'Điểm đến là đảo, cần đi phà hoặc tàu cao tốc từ cảng đất liền.'),
      ];
    }
    if (fromIsland && !toIsland) {
      if (_hasDirectIslandFlight(to, from)) {
        return [
          _manualLeg(orderStart, fromName, from, to, TransportMode.flight,
              'Hai điểm có tuyến bay phù hợp, máy bay là phương án khả thi và nhanh nhất.'),
        ];
      }
      if (_prefersFastIslandRoute(budgetPerPerson) && _hasAirport(from)) {
        final airport = _nearestAirportForIslandRoute(to, from);
        return [
          _manualLeg(orderStart, fromName, from, airport, TransportMode.flight,
              'Rời đảo bằng máy bay để tiết kiệm thời gian.'),
          _autoLeg(orderStart + 1, airport.name, airport, to),
        ];
      }
      final port = _mainlandPortForIsland(from);
      return [
        _manualLeg(orderStart, fromName, from, port, TransportMode.ferry, 'Rời đảo bằng phà hoặc tàu cao tốc về cảng đất liền.'),
        _autoLeg(orderStart + 1, port.name, port, to),
      ];
    }
    final distance = _distanceKm(from.latitude, from.longitude, to.latitude, to.longitude);
    if (_prefersFastIslandRoute(budgetPerPerson) &&
        distance >= 550 &&
        !_hasAirport(to)) {
      final fromAirport = _nearestAirportForGroundRoute(from);
      final toAirport = _nearestAirportForGroundRoute(to);
      if (fromAirport.id != toAirport.id && _hasAirport(fromAirport) && _hasAirport(toAirport)) {
        final legs = <RouteLeg>[];
        var order = orderStart;
        if (!_samePlace(from, fromAirport)) {
          legs.add(_autoLeg(order, fromName, from, fromAirport));
          order++;
        }
        legs.add(
          _manualLeg(
            order,
            _samePlace(from, fromAirport) ? fromName : fromAirport.name,
            fromAirport,
            toAirport,
            TransportMode.flight,
            'Điểm đến không có sân bay, bay đến sân bay gần nhất rồi đi tiếp bằng đường bộ.',
          ),
        );
        order++;
        if (!_samePlace(toAirport, to)) {
          legs.add(_autoLeg(order, toAirport.name, toAirport, to));
        }
        if (legs.length > 1) return legs;
      }
    }
    return [_autoLeg(orderStart, fromName, from, to)];
  }

  static RouteLeg _autoLeg(int order, String fromName, Destination from, Destination to) {
    final distance = _distanceKm(from.latitude, from.longitude, to.latitude, to.longitude);
    final mode = _recommendedMode(distance, from.region, to.region, from, to);
    return _manualLeg(order, fromName, from, to, mode, _reason(mode));
  }

  static RouteLeg _manualLeg(int order, String fromName, Destination from, Destination to, TransportMode mode, String reason) {
    final distance = _distanceKm(from.latitude, from.longitude, to.latitude, to.longitude);
    return RouteLeg(order: order, fromName: fromName, to: to, distanceKm: distance, recommendedMode: mode, reason: reason);
  }

  static TransportMode _recommendedMode(double distanceKm, String fromRegion, String toRegion, Destination from, Destination to) {
    if (_hasAirport(from) && _hasAirport(to) && distanceKm > 500) return TransportMode.flight;
    if ((_isAirportPlace(from) || _isAirportPlace(to)) && distanceKm < 150) {
      return TransportMode.car;
    }
    if (distanceKm < 150 && fromRegion == toRegion) return TransportMode.motorbike;
    if (distanceKm < 150) return TransportMode.car;
    if (_hasRail(from) && _hasRail(to) && distanceKm <= 700) return TransportMode.train;
    return TransportMode.coach;
  }

  static String _reason(TransportMode mode) {
    switch (mode) {
      case TransportMode.motorbike:
        return 'Chặng ngắn cùng vùng, xe máy linh hoạt và tiết kiệm.';
      case TransportMode.car:
        return 'Chặng ngắn, ô tô/taxi thuận tiện và có đường bộ trực tiếp.';
      case TransportMode.coach:
        return 'Có kết nối đường bộ, xe khách phù hợp chi phí và không cần sân bay.';
      case TransportMode.train:
        return 'Hai điểm có kết nối đường sắt, tàu hỏa ổn định cho chặng trung bình.';
      case TransportMode.ferry:
        return 'Điểm đến hoặc điểm đi là đảo, cần phà hoặc tàu cao tốc.';
      case TransportMode.flight:
        return 'Hai điểm có sân bay, máy bay tiết kiệm thời gian cho chặng dài.';
    }
  }

  static bool _isIsland(Destination d) {
    final value = _norm(d.name);
    return value.contains('phu quoc') ||
        value.contains('con dao') ||
        d.id.contains('phu_quoc') ||
        d.id.contains('con_dao');
  }

  static bool _hasDirectIslandFlight(Destination mainland, Destination island) {
    final from = _norm(mainland.name);
    final to = _norm(island.name);
    if (to.contains('phu quoc')) {
      return from.contains('ho chi minh') ||
          from.contains('tp.hcm') ||
          from.contains('ha noi') ||
          from.contains('da nang');
    }
    if (to.contains('con dao')) {
      return from.contains('ho chi minh') || from.contains('tp.hcm');
    }
    return false;
  }

  static bool _prefersFastIslandRoute(double? budgetPerPerson) =>
      budgetPerPerson != null && budgetPerPerson >= 3000000;

  static Destination _nearestAirportForIslandRoute(Destination from, Destination island) {
    final name = _norm(from.name);
    final region = _norm(from.region);
    if (_hasDirectIslandFlight(from, island)) return from;
    if (name.contains('ha noi') || region.contains('bac')) return _noiBaiAirport;
    if (name.contains('da nang') || region.contains('trung')) return _daNangAirport;
    return _tanSonNhatAirport;
  }

  static Destination _nearestAirportForGroundRoute(Destination place) {
    final name = _norm(place.name);
    final region = _norm(place.region);
    if (_hasAirport(place)) return place;
    if (name.contains('sa pa') ||
        name.contains('sapa') ||
        name.contains('ha noi') ||
        name.contains('ninh binh') ||
        region.contains('bac')) {
      return _noiBaiAirport;
    }
    if (name.contains('hoi an') ||
        name.contains('da nang') ||
        name.contains('hue') ||
        region.contains('trung')) {
      return _daNangAirport;
    }
    return _tanSonNhatAirport;
  }

  static bool _samePlace(Destination a, Destination b) {
    if (a.id.isNotEmpty && a.id == b.id) return true;
    return _distanceKm(a.latitude, a.longitude, b.latitude, b.longitude) < 8;
  }

  static bool _hasAirport(Destination d) =>
      _airportNames.any((name) => _norm(d.name).contains(name)) ||
      _norm(d.name).contains('san bay');
  static bool _isAirportPlace(Destination d) =>
      _norm(d.name).contains('san bay') || d.id.contains('airport');
  static bool _hasRail(Destination d) => _railNames.any((name) => _norm(d.name).contains(name));
  static Destination _mainlandPortForIsland(Destination island) {
    if (_norm(island.name).contains('con dao') || island.id.contains('con_dao')) {
      return _tranDePort;
    }
    return _haTienPort;
  }

  static String _norm(String value) {
    return value.toLowerCase()
        .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
        .replaceAll('đ', 'd');
  }

  static const _airportNames = {'ha noi', 'ho chi minh', 'tp.hcm', 'da nang', 'hue', 'nha trang', 'da lat', 'phu quoc', 'con dao', 'quy nhon', 'can tho', 'vinh'};
  static const _railNames = {'ha noi', 'vinh', 'hue', 'da nang', 'nha trang', 'quy nhon', 'ho chi minh', 'tp.hcm'};
  static const _haTienPort = Destination(id: 'ha_tien_port', name: 'Cảng Hà Tiên', region: 'Miền Tây', latitude: 10.3833, longitude: 104.4833, highlight: 'Bến phà/tàu cao tốc đi Phú Quốc');
  static const _tranDePort = Destination(id: 'tran_de_port', name: 'Cảng Trần Đề', region: 'Miền Tây', latitude: 9.4969, longitude: 106.2089, highlight: 'Bến tàu cao tốc đi Côn Đảo');
  static const _tanSonNhatAirport = Destination(id: 'tan_son_nhat_airport', name: 'Sân bay Tân Sơn Nhất', region: 'Miền Nam', latitude: 10.8188, longitude: 106.6519, highlight: 'Sân bay gần TP.HCM và Bình Dương');
  static const _noiBaiAirport = Destination(id: 'noi_bai_airport', name: 'Sân bay Nội Bài', region: 'Miền Bắc', latitude: 21.2187, longitude: 105.8042, highlight: 'Sân bay gần Hà Nội');
  static const _daNangAirport = Destination(id: 'da_nang_airport', name: 'Sân bay Đà Nẵng', region: 'Miền Trung', latitude: 16.0439, longitude: 108.1994, highlight: 'Sân bay gần Đà Nẵng');
}



