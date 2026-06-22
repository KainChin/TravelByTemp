import 'package:flutter/material.dart';

import '../models/budget_tier.dart';
import '../models/destination.dart';

/// Quản lý toàn bộ state của màn hình "Tạo hành trình mới":
/// điểm xuất phát, danh sách điểm đến đã chọn (theo thứ tự), ngày đi/về,
/// số lượng người và ngân sách mỗi người.
class TripFormProvider extends ChangeNotifier {
  static const String defaultDeparturePoint = 'Hồ Chí Minh, Việt Nam';

  final String departurePoint;
  final List<SelectedDestination> _selectedDestinations = [];
  DateTime? departureDate;
  DateTime? returnDate;
  int peopleCount = 2;

  /// Index trong [BudgetTier.tiers] — mặc định nấc "1 triệu".
  int budgetTierIndex = 2;

  TripFormProvider({this.departurePoint = defaultDeparturePoint});

  List<SelectedDestination> get selectedDestinations =>
      List.unmodifiable(_selectedDestinations);

  double get budgetPerPerson => BudgetTier.tiers[budgetTierIndex].value;

  String get budgetLabel => BudgetTier.formatCurrency(budgetPerPerson);

  /// Nhãn điểm xuất phát cho điểm đến kế tiếp: là điểm xuất phát ban đầu
  /// nếu danh sách đang trống, ngược lại là điểm đến cuối cùng đã chọn.
  String get nextOriginLabel => _selectedDestinations.isEmpty
      ? departurePoint
      : _selectedDestinations.last.destination.name;

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

  /// Sau khi xoá/sắp xếp lại, nhãn "fromLabel" của từng điểm phải được
  /// tính lại theo đúng thứ tự mới (điểm sau luôn xuất phát từ điểm trước).
  void _recomputeFromLabels() {
    for (int i = 0; i < _selectedDestinations.length; i++) {
      final origin =
      i == 0 ? departurePoint : _selectedDestinations[i - 1].destination.name;
      _selectedDestinations[i] = SelectedDestination(
        destination: _selectedDestinations[i].destination,
        fromLabel: origin,
        distanceKm: _selectedDestinations[i].distanceKm,
      );
    }
  }

  void setDepartureDate(DateTime date) {
    departureDate = date;
    if (returnDate != null && returnDate!.isBefore(date)) {
      returnDate = null;
    }
    notifyListeners();
  }

  void setReturnDate(DateTime date) {
    returnDate = date;
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

  void setBudgetTierIndex(int index) {
    if (index < 0 || index >= BudgetTier.tiers.length) return;
    budgetTierIndex = index;
    notifyListeners();
  }

  bool get canAnalyze =>
      _selectedDestinations.isNotEmpty &&
          departureDate != null &&
          returnDate != null;
}