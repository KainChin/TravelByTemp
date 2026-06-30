import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/budget_tier.dart';
import '../models/destination.dart';
import '../models/route_analysis.dart';
import '../services/trip_itinerary_service.dart';

class TripFormProvider extends ChangeNotifier {
  static const String defaultDeparturePoint = 'Hồ Chí Minh, Việt Nam';

  TripFormProvider({this.departurePoint = defaultDeparturePoint});

  final String departurePoint;
  final List<SelectedDestination> _selectedDestinations = [];
  Destination _departure = DestinationCatalog.hoChiMinh;

  int peopleCount = 2;
  bool isAnalyzing = false;
  bool isLocating = false;
  String? analyzeError;
  String? locationError;
  TripItineraryResult? itineraryResult;

  double _budgetPerPerson = 3000000;

  List<SelectedDestination> get selectedDestinations =>
      List.unmodifiable(_selectedDestinations);

  DateTime? get departureDate =>
      _selectedDestinations.isEmpty ? null : _selectedDestinations.first.startDate;

  DateTime? get returnDate =>
      _selectedDestinations.isEmpty ? null : _selectedDestinations.last.endDate;

  double get budgetPerPerson => _budgetPerPerson;

  double get budgetPerTraveler => peopleCount <= 0 ? _budgetPerPerson : _budgetPerPerson / peopleCount;

  String get budgetLabel => BudgetTier.formatCurrency(budgetPerPerson);

  Destination get departure => _departure;

  String get departureLabel => _departure.name;

  String get nextOriginLabel => _selectedDestinations.isEmpty
      ? departureLabel
      : _selectedDestinations.last.destination.name;

  Future<void> detectCurrentLocation() async {
    if (isLocating) return;
    isLocating = true;
    locationError = null;
    notifyListeners();

    try {
      var serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationError = 'Vui lòng bật định vị trên thiết bị.';
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        locationError = 'Bạn cần cấp quyền vị trí để lấy điểm xuất phát chính xác.';
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final name = await _locationName(position);
      _departure = Destination(
        id: 'current_location',
        name: name,
        region: 'Vị trí hiện tại',
        latitude: position.latitude,
        longitude: position.longitude,
        highlight: 'Tọa độ GPS hiện tại',
      );
      _recomputeFromLabels();
    } catch (_) {
      locationError = 'Không lấy được vị trí hiện tại. Hãy thử lại.';
    } finally {
      isLocating = false;
      notifyListeners();
    }
  }

  void addDestination(Destination destination, {double distanceKm = 0}) {
    _selectedDestinations.add(
      SelectedDestination(
        destination: destination,
        fromLabel: nextOriginLabel,
        distanceKm: distanceKm,
      ),
    );
    notifyListeners();
  }

  void removeDestinationAt(int index) {
    if (index < 0 || index >= _selectedDestinations.length) return;
    _selectedDestinations.removeAt(index);
    _recomputeFromLabels();
    notifyListeners();
  }

  void reorderDestination(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _selectedDestinations.removeAt(oldIndex);
    _selectedDestinations.insert(newIndex, item);
    _recomputeFromLabels();
    notifyListeners();
  }

  void _recomputeFromLabels() {
    for (int i = 0; i < _selectedDestinations.length; i++) {
      final origin =
          i == 0 ? departureLabel : _selectedDestinations[i - 1].destination.name;
      _selectedDestinations[i] = _selectedDestinations[i].copyWith(
        fromLabel: origin,
      );
    }
  }

  void setTripDates(DateTime start, DateTime end) {
    var normalizedStart = _dateOnly(start);
    var normalizedEnd = _dateOnly(end);
    if (normalizedEnd.isBefore(normalizedStart)) normalizedEnd = normalizedStart;
    for (var i = 0; i < _selectedDestinations.length; i++) {
      _selectedDestinations[i] = _selectedDestinations[i].copyWith(
        startDate: normalizedStart,
        endDate: normalizedEnd,
      );
    }
    notifyListeners();
  }

  void setDestinationDates(int index, DateTime start, DateTime end) {
    if (index < 0 || index >= _selectedDestinations.length) return;
    var normalizedStart = _dateOnly(start);
    var normalizedEnd = _dateOnly(end);
    final minDate = firstSelectableDateForDestination(index);
    if (normalizedStart.isBefore(minDate)) normalizedStart = minDate;
    if (normalizedEnd.isBefore(normalizedStart)) normalizedEnd = normalizedStart;

    _selectedDestinations[index] = _selectedDestinations[index].copyWith(
      startDate: normalizedStart,
      endDate: normalizedEnd,
    );
    _clearInvalidDatesFrom(index + 1);
    notifyListeners();
  }

  void incrementPeople() {
    peopleCount++;
    notifyListeners();
  }

  void decrementPeople() {
    if (peopleCount <= 1) return;
    peopleCount--;
    notifyListeners();
  }

  void setPeopleCount(int value) {
    peopleCount = value.clamp(1, 99);
    notifyListeners();
  }

  void setBudgetPerPerson(double value) {
    _budgetPerPerson =
        value.clamp(BudgetTier.minBudget, BudgetTier.maxBudget).toDouble();
    notifyListeners();
  }

  DateTime firstSelectableDateForDestination(int index) {
    final today = _dateOnly(DateTime.now());
    if (index <= 0 || index >= _selectedDestinations.length) return today;
    return _selectedDestinations[index - 1].endDate ?? today;
  }

  String? destinationDateError(int index) {
    if (index < 0 || index >= _selectedDestinations.length) return null;
    final item = _selectedDestinations[index];
    if (item.startDate == null || item.endDate == null) {
      return 'Chọn ngày đến và ngày rời cho điểm này.';
    }
    if (item.endDate!.isBefore(item.startDate!)) {
      return 'Ngày rời phải sau hoặc bằng ngày đến.';
    }
    if (index > 0) {
      final previousEnd = _selectedDestinations[index - 1].endDate;
      if (previousEnd != null && item.startDate!.isBefore(previousEnd)) {
        return 'Điểm sau phải bắt đầu từ ngày rời điểm trước trở đi.';
      }
    }
    return null;
  }

  String? get tripDateError {
    if (departureDate == null || returnDate == null) {
      return 'Chọn ngày cho từng điểm đến.';
    }
    if (returnDate!.isBefore(departureDate!)) {
      return 'Ngày kết thúc phải sau ngày đi.';
    }
    return null;
  }

  bool get _hasValidDestinationDates {
    for (var i = 0; i < _selectedDestinations.length; i++) {
      if (destinationDateError(i) != null) return false;
    }
    return true;
  }

  bool get canAnalyze =>
      _selectedDestinations.isNotEmpty &&
      departureDate != null &&
      returnDate != null &&
      tripDateError == null &&
      _hasValidDestinationDates &&
      !isAnalyzing;

  TripRouteAnalysis buildRouteAnalysis() {
    return TripRouteAnalysis.from(
      departurePoint: departureLabel,
      departure: departure,
      selectedDestinations: _selectedDestinations,
      budgetPerPerson: budgetPerTraveler,
    );
  }

  Future<TripRouteAnalysis?> analyzeRoute() async {
    if (!canAnalyze) return null;

    isAnalyzing = true;
    analyzeError = null;
    notifyListeners();

    final service = TripItineraryService();
    try {
      return await service.analyzeRoute(
        departurePoint: departureLabel,
        departure: departure,
        destinations: _selectedDestinations,
        peopleCount: peopleCount,
        budgetPerPerson: budgetPerTraveler,
      );
    } on TripItineraryException catch (e) {
      analyzeError = e.message;
      return null;
    } finally {
      service.dispose();
      isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<TripItineraryResult?> analyzeTrip() async {
    if (!canAnalyze || departureDate == null || returnDate == null) return null;

    isAnalyzing = true;
    analyzeError = null;
    itineraryResult = null;
    notifyListeners();

    final service = TripItineraryService();
    try {
      final result = await service.generate(
        destinations: _selectedDestinations,
        departureDate: departureDate!,
        returnDate: returnDate!,
        peopleCount: peopleCount,
        budgetPerPerson: budgetPerPerson,
        departurePoint: departureLabel,
      );
      itineraryResult = result;
      return result;
    } on TripItineraryException catch (e) {
      analyzeError = e.message;
      return null;
    } finally {
      service.dispose();
      isAnalyzing = false;
      notifyListeners();
    }
  }

  void _clearInvalidDatesFrom(int startIndex) {
    for (var i = startIndex; i < _selectedDestinations.length; i++) {
      final item = _selectedDestinations[i];
      final minDate = firstSelectableDateForDestination(i);
      var start = item.startDate;
      var end = item.endDate;

      if (start != null && start.isBefore(minDate)) start = minDate;
      if (end != null && start != null && end.isBefore(start)) end = start;

      _selectedDestinations[i] = item.copyWith(
        startDate: start,
        endDate: end,
        clearStartDate: start == null,
        clearEndDate: end == null,
      );
    }
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  Future<String> _locationName(Position position) async {
    try {
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (places.isEmpty) return 'Vị trí hiện tại';
      final place = places.first;
      final parts = [
        place.subLocality,
        place.locality,
        place.administrativeArea,
      ].where((part) => part != null && part.trim().isNotEmpty).cast<String>();
      final label = parts.join(', ');
      return label.isEmpty ? 'Vị trí hiện tại' : label;
    } catch (_) {
      return 'Vị trí hiện tại';
    }
  }
}
