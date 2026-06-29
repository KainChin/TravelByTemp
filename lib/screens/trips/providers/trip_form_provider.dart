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
  DateTime? _departureDate;
  DateTime? _returnDate;

  List<SelectedDestination> get selectedDestinations =>
      List.unmodifiable(_selectedDestinations);

  DateTime? get departureDate => _departureDate;

  DateTime? get returnDate => _returnDate;

  double get budgetPerPerson => _budgetPerPerson;

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
        startDate: _departureDate,
        endDate: _returnDate,
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
    _departureDate = normalizedStart;
    _returnDate = normalizedEnd;
    for (var i = 0; i < _selectedDestinations.length; i++) {
      _selectedDestinations[i] = _selectedDestinations[i].copyWith(
        startDate: normalizedStart,
        endDate: normalizedEnd,
      );
    }
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

  void setBudgetPerPerson(double value) {
    _budgetPerPerson =
        value.clamp(BudgetTier.minBudget, BudgetTier.maxBudget).toDouble();
    notifyListeners();
  }

  DateTime firstSelectableDateForDestination(int index) => _dateOnly(DateTime.now());

  String? destinationDateError(int index) {
    if (index < 0 || index >= _selectedDestinations.length) return null;
    final item = _selectedDestinations[index];
    if (item.startDate == null || item.endDate == null) {
      return 'Chọn ngày bắt đầu và kết thúc cho chặng này.';
    }
    if (item.endDate!.isBefore(item.startDate!)) {
      return 'Ngày kết thúc phải sau hoặc bằng ngày bắt đầu.';
    }
    if (index > 0) {
      final previousEnd = _selectedDestinations[index - 1].endDate;
      if (previousEnd != null && item.startDate!.isBefore(previousEnd)) {
        return 'Chặng sau phải bắt đầu từ ngày kết thúc chặng trước trở đi.';
      }
    }
    return null;
  }

  String? get tripDateError {
    if (_departureDate == null || _returnDate == null) {
      return 'Chon ngay di va ngay ket thuc chuyen di.';
    }
    if (_returnDate!.isBefore(_departureDate!)) {
      return 'Ngay ket thuc phai sau ngay di.';
    }
    return null;
  }

  bool get canAnalyze =>
      _selectedDestinations.isNotEmpty &&
      departureDate != null &&
      returnDate != null &&
      tripDateError == null &&
      !isAnalyzing;

  TripRouteAnalysis buildRouteAnalysis() {
    return TripRouteAnalysis.from(
      departurePoint: departureLabel,
      departure: departure,
      selectedDestinations: _selectedDestinations,
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
        budgetPerPerson: budgetPerPerson,
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
