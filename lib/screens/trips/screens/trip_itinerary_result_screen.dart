// ignore_for_file: unnecessary_library_name

library trip_itinerary_result_screen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:assignment/core/keys/app_keys.dart';
import 'package:assignment/core/strings/itinerary_strings.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/saved_itinerary_store.dart';
import '../services/trip_itinerary_service.dart';
import '../../main_shell.dart';

part 'itinerary_result/trip_itinerary_result_overview.dart';
part 'itinerary_result/trip_itinerary_result_map.dart';
part 'itinerary_result/trip_itinerary_result_timeline.dart';
part 'itinerary_result/trip_itinerary_result_budget.dart';
part 'itinerary_result/trip_itinerary_result_insights.dart';
part 'itinerary_result/trip_itinerary_result_ai_chat.dart';
part 'itinerary_result/trip_itinerary_result_common.dart';
part 'itinerary_result/trip_itinerary_result_schedule_helpers.dart';
part 'itinerary_result/trip_itinerary_result_budget_helpers.dart';
part 'itinerary_result/trip_itinerary_result_activity_helpers.dart';
part 'itinerary_result/trip_itinerary_result_ai_helpers.dart';
part 'itinerary_result/trip_itinerary_result_location_helpers.dart';

class TripItineraryResultScreen extends StatefulWidget {
  const TripItineraryResultScreen({
    super.key,
    required this.response,
    required this.itinerary,
    this.itineraryId,
  });

  final String response;
  final Map<String, dynamic> itinerary;
  final String? itineraryId;

  @override
  State<TripItineraryResultScreen> createState() => _TripItineraryResultScreenState();
}

class _TripItineraryResultScreenState extends State<TripItineraryResultScreen> {
  static const _bg = Color(0xFFF5F7F4);
  static const _ink = Color(0xFF15221D);
  static const _muted = Color(0xFF6E7A74);
  static const _line = Color(0xFFE2E8E4);
  static const _primary = Color(0xFF008F6A);
  static const _primarySoft = Color(0xFFE6F6F0);
  static const _accent = Color(0xFFFF8A5B);

  late List<Map<String, dynamic>> _days;
  int _selectedDayIndex = 0;
  // Mặc định chưa lưu. Chỉ set true khi user bấm nút "Lưu hành trình".
  // (Không dựa vào itineraryId từ response, vì backend có thể trả ID cho
  // trip draft chưa user save chính thức.)
  bool _isSaved = false;
  bool _isSaving = false;
  String? _remoteItineraryId;

  @override
  void initState() {
    super.initState();
    _days = _normalizeDays(widget.itinerary['days']);
    // Không tự set _isSaved = true ở đây. Nếu user mở từ tab "Đã lưu" thì
    // widget caller (saved_screen / history_screen) nên pass cờ rõ ràng.
    // Hiện tại để đơn giản và nhất quán, mọi trip đều bắt đầu ở trạng thái
    // chưa lưu — user phải bấm nút để chuyển sang "Đã lưu".
    _remoteItineraryId = widget.itineraryId;
  }

  String get _title {
    final title = '${widget.itinerary['title'] ?? ''}'.trim();
    if (title.isNotEmpty) return title;
    return _days.isEmpty ? ItineraryStrings.titleFallback : ItineraryStrings.titleByDay;
  }

  String get _summary {
    final summary = '${widget.itinerary['summary'] ?? widget.response}'.trim();
    return summary.isEmpty ? ItineraryStrings.defaultSummary : summary;
  }

  /// Cost breakdown cho cả chuyến đi.
///
/// Lưu ý về quy ước cost:
/// - Activities lưu **giá cho 1 người** (per-person) để user dễ edit sau.
/// - Khi mua vé tàu/xe/ferry/flight thực tế phải nhân với số người; UI hiển thị
///   ở [TripInsightsSection] sẽ tự động nhân với `_peopleCount` cho hạng mục
///   'di chuyển' thuộc nhóm per-ticket (flight/ferry/train/motorbike).
/// - Activities 'di chuyển' loại per-group (car thuê nguyên, coach thuê nguyên)
///   nên đánh dấu `transportMode: 'car'` hoặc `'coach'` trong map, hệ thống
///   sẽ không nhân.
Map<String, num> get _costBreakdown {
    // Activities lưu per-person. Transport per-ticket (flight/ferry/train/
    // motorbike) nhân theo số người; car/coach giữ nguyên (per-group).
    final people = _peopleCount;
    var transport = 0;
    var food = 0;
    var stay = 0;
    var activities = 0;
    for (final day in _days) {
      for (final item in _activitiesFor(day)) {
        final cost = _activityCost(item);
        final category = _activityCategory(item);
        final mode = '${item['transportMode'] ?? ''}'.toLowerCase();
        final isPerTicketTransport = mode == 'flight' ||
            mode == 'ferry' ||
            mode == 'train' ||
            mode == 'motorbike';
        if (category == 'ăn uống') {
          food += cost * people;
        } else if (category == 'khách sạn') {
          stay += cost * people;
        } else if (category == 'di chuyển') {
          transport += isPerTicketTransport ? cost * people : cost;
        } else {
          activities += cost * people;
        }
      }
    }
    // Nếu module AI không trả cost cho 'di chuyển' nhưng module route analysis
    // đã có sẵn (cùng 1 chuyến), dùng cost từ route analysis để đảm bảo số
    // liệu đồng bộ giữa 2 màn hình và khớp với thực tế người dùng đã chọn.
    final override = _routeAnalysisTransportCost;
    if (override > transport) transport = override.round();
    final total = transport + food + stay + activities;
    return {
      'transport': transport,
      'food': food,
      'accommodation': stay,
      'activities': activities,
      'total': total,
    };
  }

  /// Tổng tiền di chuyển (VND, cho cả nhóm) được dựng từ dữ liệu route analysis
  /// đã lưu trong itinerary. Ưu tiên:
  /// 1. `itinerary['transportCost']` — server/service có thể đính kèm sẵn.
  /// 2. `itinerary['routeAnalysis']['totalTransportCost']` — tổng tiền cả tuyến.
  /// 3. Tự tính lại từ `itinerary['routeAnalysis']['legs']` nếu có.
  /// Trả về 0 nếu không tìm được nguồn nào.
  num get _routeAnalysisTransportCost {
    final itinerary = widget.itinerary;
    final direct = _readBudgetMap(itinerary, const ['transportCost', 'totalTransportCost']);
    if (direct > 0) return direct;

    final analysis = itinerary['routeAnalysis'];
    if (analysis is Map) {
      final analysisCost = _readBudgetMap(Map<String, dynamic>.from(analysis), const [
        'totalTransportCost',
        'estimatedRouteCostVnd',
        'totalCost',
      ]);
      if (analysisCost > 0) return analysisCost;

      // Tự cộng dồn cost từ các legs (per-group nếu có sẵn).
      final legs = analysis['legs'];
      if (legs is List) {
        num sum = 0;
        for (final leg in legs.whereType<Map>()) {
          final m = Map<String, dynamic>.from(leg);
          sum += _readBudgetMap(m, const [
            'selectedCost',
            'cost',
            'totalCost',
            'price',
          ]);
        }
        if (sum > 0) return sum;
      }
    }
    return 0;
  }

  /// Helper: đọc 1 key (có fallback list) từ map, hỗ trợ num/String.
  num _readBudgetMap(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is num && value > 0) return value;
      if (value is String) {
        final parsed = num.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return 0;
  }

  num? get _userBudget => _readBudget(widget.itinerary);

  int get _peopleCount {
    final raw = widget.itinerary['peopleCount'] ?? widget.itinerary['people'];
    if (raw is num && raw > 0) return raw.round();
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null && parsed > 0) return parsed;
    }
    return 1;
  }

  int get _totalActivities => _days.fold(0, (sum, day) => sum + _activitiesFor(day).length);

  int get _destinationCount {
    final names = <String>{};
    for (final day in _days) {
      for (final activity in _activitiesFor(day)) {
        final destination = '${activity['destination'] ?? ''}'.trim();
        if (destination.isNotEmpty && destination != 'null') names.add(destination);
      }
    }
    return names.length;
  }

  /// AI score (0–10) đánh giá chất lượng lịch trình thật, dựa trên:
/// - **Hoạt động mỗi ngày**: 3–6 = tốt, <2 hoặc >8 = chưa tối ưu.
/// - **Phân bổ ngân sách**: cost ≈ budget là điểm tốt; vượt quá nhiều bị trừ.
/// - **Khoảng cách trung bình giữa các hoạt động** trong ngày (nếu có lat/lng):
///   1–15 km là hợp lý; >50 km gợi ý chuyển động nhiều.
/// - **Category coverage**: có đủ ăn uống + lưu trú + tham quan.
/// - **Trùng giờ**: nếu có nhiều cặp activity trùng giờ → trừ điểm.
double get _aiScore {
    if (_days.isEmpty) return 0;

    var score = 5.5;

    // 1) Mật độ hoạt động mỗi ngày
    final avgPerDay = _totalActivities / _days.length;
    if (avgPerDay >= 3 && avgPerDay <= 6) {
      score += 1.0;
    } else if (avgPerDay >= 2 && avgPerDay <= 8) {
      score += 0.5;
    } else if (avgPerDay > 8) {
      score -= 0.3;
    }

    // 2) Category coverage
    final hasFood = _days.any((d) => _activitiesFor(d).any((a) => _activityCategory(a) == 'ăn uống'));
    final hasStay = _days.any((d) => _activitiesFor(d).any((a) => _activityCategory(a) == 'khách sạn'));
    final hasActivity = _days.any((d) => _activitiesFor(d).any((a) => _activityCategory(a) == 'tham quan'));
    final coverage = (hasFood ? 1 : 0) + (hasStay ? 1 : 0) + (hasActivity ? 1 : 0);
    if (coverage == 3) {
      score += 0.9;
    } else if (coverage == 2) {
      score += 0.4;
    } else if (coverage <= 1) {
      score -= 0.4;
    }

    // 3) Khoảng cách trung bình giữa các hoạt động có lat/lng
    final distances = <double>[];
    for (final day in _days) {
      final activities = _activitiesFor(day);
      for (var i = 0; i < activities.length - 1; i++) {
        final a = activities[i];
        final b = activities[i + 1];
        final aLat = _numValue(a['latitude'] ?? a['lat']);
        final aLng = _numValue(a['longitude'] ?? a['lng']);
        final bLat = _numValue(b['latitude'] ?? b['lat']);
        final bLng = _numValue(b['longitude'] ?? b['lng']);
        if (aLat != null && aLng != null && bLat != null && bLng != null) {
          distances.add(const Distance().as(
            LengthUnit.Kilometer,
            LatLng(aLat, aLng),
            LatLng(bLat, bLng),
          ));
        }
      }
    }
    if (distances.isNotEmpty) {
      final avgKm = distances.reduce((a, b) => a + b) / distances.length;
      if (avgKm >= 1 && avgKm <= 15) {
        score += 0.5;
      } else if (avgKm > 50) {
        score -= 0.4;
      } else if (avgKm > 30) {
        score -= 0.2;
      }
    }

    // 4) Budget fit
    final total = _costBreakdown['total'] ?? 0;
    final budget = _userBudget;
    if (total > 0 && budget != null && budget > 0) {
      final ratio = total / budget;
      if (ratio >= 0.6 && ratio <= 1.0) {
        score += 0.6;
      } else if (ratio > 1.2) {
        score -= 0.5;
      } else if (ratio < 0.3) {
        score -= 0.2;
      }
    } else if (total > 0) {
      score += 0.3;
    }

    return score.clamp(0.0, 10.0).toDouble();
  }

  double? _numValue(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> _saveItinerary() async {
    if (_isSaving) return;
    final itinerary = Map<String, dynamic>.from(widget.itinerary);
    final existingId = _remoteItineraryId ??
        (widget.itinerary['id'] != null ? '${widget.itinerary['id']}' : null) ??
        (widget.itineraryId);
    if (existingId != null && existingId.isNotEmpty) {
      itinerary['id'] = existingId;
      itinerary['itineraryId'] = existingId;
    }
    itinerary['days'] = _days;
    var savedToDatabase = false;
    final token = VietaiScope.of(context).auth?.accessToken;
    setState(() => _isSaving = true);
    try {
      final remote = await TripItineraryService(authToken: token).saveItinerary(
        itineraryId: existingId,
        itinerary: itinerary,
      );
      _remoteItineraryId = remote.id;
      itinerary['id'] = remote.id;
      itinerary['itineraryId'] = remote.id;
      savedToDatabase = true;
    } on TripItineraryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chưa lưu được lên database, app sẽ lưu tạm local. $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    await SavedItineraryStore.save(itinerary);
    if (!mounted) return;
    setState(() {
      _isSaved = true;
    });
    final savedToDatabaseFinal = savedToDatabase;
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(savedToDatabaseFinal ? ItineraryStrings.snackSavedToDatabase : ItineraryStrings.snackSavedLocally),
      ),
    );
    // Pop về MainShell rồi chuyển sang tab "Đã lưu" để user thấy ngay item vừa lưu.
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
    MainShell.goToSavedTab();
  }

  void _openChat({String? initialPrompt}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        final day = _days.isEmpty ? null : _days[_selectedDayIndex];
        return _AiChatSheet(
          title: _title,
          dayLabel: day == null ? 'Chưa chọn ngày' : 'Ngày ${day['day'] ?? _selectedDayIndex + 1}',
          budgetLabel: _budgetLabel(_userBudget),
          initialPrompt: initialPrompt,
          onApply: (changes) {
            _applyAiChanges(changes);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _applyAiChanges(List<_AiChange> changes) {
    if (_days.isEmpty || changes.isEmpty) return;
    final selected = _days[_selectedDayIndex];
    final items = _activitiesFor(selected).toList();
    final seen = <String>{
      for (final item in items)
        _activityKey(item['time'], item['destination'] ?? item['title'] ?? item['name']),
    };
    setState(() {
      for (final change in changes) {
        if (change.kind == _AiChangeKind.reduceCost) {
          for (final item in items) {
            final current = _activityCost(item);
            item['estimatedCost'] = (current * 0.88).round();
          }
        } else {
          final newItem = _newActivity(_kindFor(change.kind));
          final key = _activityKey(newItem['time'], newItem['destination'] ?? newItem['title'] ?? newItem['name']);
          if (seen.add(key)) {
            items.add(newItem);
          }
        }
      }
      selected['activities'] = items;
    });
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text(ItineraryStrings.snackAiApplied)),
    );
  }

  String _kindFor(_AiChangeKind kind) {
    switch (kind) {
      case _AiChangeKind.addFood:
        return 'restaurant';
      case _AiChangeKind.addHotel:
        return 'hotel';
      case _AiChangeKind.addPlace:
        return 'place';
      case _AiChangeKind.transport:
        return 'transport';
      case _AiChangeKind.reduceCost:
        return 'activity';
    }
  }

  String _activityKey(dynamic time, dynamic name) =>
      '${(time ?? '').toString().trim()}|${(name ?? '').toString().trim()}';

  void _showActivityEditor({Map<String, dynamic>? activity, int? index, String kind = 'activity'}) {
    final current = activity ?? <String, dynamic>{};
    final time = TextEditingController(text: '${current['time'] ?? '09:00'}');
    final title = TextEditingController(text: _activityTitle(current));
    final destination = TextEditingController(text: '${current['destination'] ?? ''}');
    final cost = TextEditingController(text: '${_activityCost(current)}');
    final note = TextEditingController(text: '${current['note'] ?? ''}');
    final address = TextEditingController(text: '${current['address'] ?? ''}');
    final duration = TextEditingController(text: '${current['duration'] ?? current['durationMinutes'] ?? ''}');
    var category = '${current['category'] ?? current['type'] ?? _categoryFromAddKind(kind)}';

    final errors = ValueNotifier<_ActivityValidationErrors>(const _ActivityValidationErrors());
    var disposed = false;

    void recomputeErrors() {
      if (disposed) return;
      final currentDay = _days.isEmpty ? null : _days[_selectedDayIndex];
      final existing = currentDay == null ? <Map<String, dynamic>>[] : _activitiesFor(currentDay).toList();
      errors.value = _validateActivityFields(
        time: time.text,
        destination: destination.text,
        costText: cost.text,
        durationText: duration.text,
        existingActivities: existing,
        editingIndex: index,
      );
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                18,
                4,
                18,
                MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    index == null ? 'Thêm ${_addKindLabel(kind).toLowerCase()}' : 'Sửa hoạt động',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<_ActivityValidationErrors>(
                    valueListenable: errors,
                    builder: (context, e, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 92,
                                child: _EditField(
                                  controller: time,
                                  label: 'Giờ',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
                                  errorText: e.time ?? e.timeConflict,
                                  onChanged: (_) => recomputeErrors(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _EditField(
                                  controller: cost,
                                  label: 'Chi phí (VNĐ)',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
                                  errorText: e.cost,
                                  onChanged: (_) => recomputeErrors(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: category,
                            items: const [
                              DropdownMenuItem(value: 'tham quan', child: Text('Tham quan')),
                              DropdownMenuItem(value: 'ăn uống', child: Text('Ăn uống')),
                              DropdownMenuItem(value: 'khách sạn', child: Text('Khách sạn')),
                              DropdownMenuItem(value: 'di chuyển', child: Text('Di chuyển')),
                            ],
                            onChanged: (value) {
                              if (value != null) setModalState(() => category = value);
                            },
                            decoration: InputDecoration(
                              labelText: 'Danh mục',
                              filled: true,
                              fillColor: _bg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _EditField(
                            controller: title,
                            label: 'Hoạt động',
                            onChanged: (_) => recomputeErrors(),
                          ),
                          const SizedBox(height: 10),
                          _EditField(
                            controller: destination,
                            label: 'Địa điểm',
                            errorText: e.destination,
                            onChanged: (_) => recomputeErrors(),
                          ),
                          const SizedBox(height: 10),
                          _EditField(controller: address, label: 'Địa chỉ'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _EditField(
                                  controller: duration,
                                  label: 'Thời lượng (phút)',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
                                  errorText: e.duration,
                                  onChanged: (_) => recomputeErrors(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: _EditField(controller: note, label: 'Ghi chú')),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        recomputeErrors();
                        if (errors.value.hasError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errors.value.first ?? 'Vui lòng kiểm tra lại thông tin.')),
                          );
                          return;
                        }
                        final selected = _days[_selectedDayIndex];
                        final items = _activitiesFor(selected).toList();
                        final next = {
                          ...current,
                          'time': time.text.trim(),
                          'activity': title.text.trim().isEmpty ? _addKindLabel(kind) : title.text.trim(),
                          'destination': destination.text.trim(),
                          'address': address.text.trim(),
                          'duration': duration.text.trim(),
                          'category': category,
                          'estimatedCost': num.tryParse(cost.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
                          'note': note.text.trim(),
                        };
                        setState(() {
                          if (index == null) {
                            items.add(next);
                          } else {
                            items[index] = next;
                          }
                          selected['activities'] = items;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(ItineraryStrings.editorSaveButton),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    ).whenComplete(() {
      disposed = true;
      errors.dispose();
      time.dispose();
      title.dispose();
      destination.dispose();
      cost.dispose();
      note.dispose();
      address.dispose();
      duration.dispose();
    });
  }

  void _showAddMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                ItineraryStrings.addMenuTitle,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                ItineraryStrings.addMenuSubtitle,
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _AddMenuTile(icon: Icons.place_outlined, label: 'Địa điểm', color: const Color(0xFF0EA5E9), onTap: () => _openAddKind(context, 'place')),
                  _AddMenuTile(icon: Icons.restaurant_outlined, label: 'Ăn uống', color: const Color(0xFFF59E0B), onTap: () => _openAddKind(context, 'restaurant')),
                  _AddMenuTile(icon: Icons.hotel_outlined, label: 'Khách sạn', color: const Color(0xFF8B5CF6), onTap: () => _openAddKind(context, 'hotel')),
                  _AddMenuTile(icon: Icons.local_activity_outlined, label: 'Hoạt động', color: const Color(0xFFEF4444), onTap: () => _openAddKind(context, 'activity')),
                  _AddMenuTile(icon: Icons.directions_bus_outlined, label: 'Di chuyển', color: const Color(0xFF10B981), onTap: () => _openAddKind(context, 'transport')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddKind(BuildContext sheetContext, String kind) {
    Navigator.pop(sheetContext);
    _showActivityEditor(kind: kind);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = _days.isEmpty ? null : _days[_selectedDayIndex.clamp(0, _days.length - 1)];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        // leading = nút back mặc định của AppBar (đã có sẵn khi push).
        title: const Text(ItineraryStrings.pageTitle, style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: _isSaved ? ItineraryStrings.tooltipSaved : ItineraryStrings.tooltipSave,
            onPressed: _isSaving ? null : _saveItinerary,
            icon: Icon(_isSaved
                ? Icons.bookmark_rounded
                : Icons.bookmark_add_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final mapHeight = (MediaQuery.sizeOf(context).height * (isWide ? 0.38 : 0.36)).clamp(320.0, 460.0);
                final timeline = TimelineSection(
                  day: selectedDay,
                  dayIndex: _selectedDayIndex,
                  totalDays: _days.length,
                  days: _days,
                  onDayChanged: (index) =>
                      setState(() => _selectedDayIndex = index),
                  onAdd: _showAddMenu,
                  onEdit: (activity, index) => _showActivityEditor(activity: activity, index: index),
                  onOptimize: (activity, index) => _openChat(
                    initialPrompt: 'Tối ưu lại hoạt động: ${_activityTitle(activity)}',
                  ),
                  onDelete: (index) {
                    final items = _activitiesFor(selectedDay).toList();
                    setState(() {
                      items.removeAt(index);
                      if (selectedDay is Map<String, dynamic>) selectedDay['activities'] = items;
                    });
                  },
                );
                final sideSections = Column(
                  children: [
                    BudgetSection(
                      cost: _costBreakdown,
                      userBudget: _userBudget,
                      onOptimizeBudget: () => _openChat(initialPrompt: 'Tối ưu ngân sách chuyến đi'),
                      onSetupBudget: () => _openChat(initialPrompt: 'Thiết lập ngân sách cho chuyến đi này'),
                    ),
                    const SizedBox(height: 14),
                    const AiInsightSection(),
                  ],
                );

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                  children: [
                    TripHeroHeader(
                      title: _title,
                      summary: _summary,
                      daysCount: _days.length,
                      destinationCount: _destinationCount,
                      activitiesCount: _totalActivities,
                      totalCost: _costBreakdown['total'] ?? 0,
                      aiScore: _aiScore,
                    ),
                    const SizedBox(height: 14),
                    if (_days.isNotEmpty)
                      DaySelector(
                        days: _days,
                        selectedIndex: _selectedDayIndex,
                        onChanged: (index) => setState(() => _selectedDayIndex = index),
                      ),
                    const SizedBox(height: 14),
                    TripMapSection(day: selectedDay, height: mapHeight),
                    const SizedBox(height: 14),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: timeline),
                          const SizedBox(width: 14),
                          Expanded(flex: 5, child: sideSections),
                        ],
                      )
                    else ...[
                      timeline,
                      const SizedBox(height: 14),
                      sideSections,
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: null,
      bottomNavigationBar: _BottomSaveBar(
        isSaved: _isSaved,
        isSaving: _isSaving,
        onSave: _saveItinerary,
        onEdit: () => _showActivityEditor(),
        onChat: _openChat,
      ),
    );
  }
}






