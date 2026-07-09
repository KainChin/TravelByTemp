// ignore_for_file: unnecessary_library_name

library create_trip_screen;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:assignment/core/widgets/safe_network_image.dart';

import '../models/destination.dart';
import '../providers/trip_form_provider.dart';
import '../widgets/budget_slider.dart';
import '../widgets/destination_picker_sheet.dart';
import '../widgets/people_counter.dart';
import 'trip_itinerary_history_screen.dart';
import 'trip_route_analysis_screen.dart';
import 'trip_planning/trip_tokens.dart';

part 'create_trip/create_trip_hero.dart';
part 'create_trip/create_trip_question_widgets.dart';
part 'create_trip/create_trip_destination_widgets.dart';

class CreateTripScreen extends StatelessWidget {
  const CreateTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TripFormProvider(),
      child: const _AiInterviewView(),
    );
  }
}

class _AiInterviewView extends StatefulWidget {
  const _AiInterviewView();

  @override
  State<_AiInterviewView> createState() => _AiInterviewViewState();
}

class _AiInterviewViewState extends State<_AiInterviewView> {
  static const _bg = Colors.white;
  static const _ink = Color(0xFF1A1F36); // Dark color for text
  static const _muted = Color(0xFF6B7280); // Gray color for subtitles
  static const _primary = kTripPrimary;
  static const _primarySoft = Color(0xFFE8F5EF);
  static const _line = kTripLine;
  static const _accent = kTripCoral;

  String _travelGroup = 'friends';
  final Set<String> _interests = {'Thiên nhiên', 'Ẩm thực'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TripFormProvider>().detectCurrentLocation();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickDestination() async {
    final form = context.read<TripFormProvider>();
    final Destination? picked = await DestinationPickerSheet.show(context);
    if (picked != null) form.addDestination(picked);
  }

  Future<void> _pickDatesForDestination(int index) async {
    final form = context.read<TripFormProvider>();
    final item = form.selectedDestinations[index];
    final firstDate = form.firstSelectableDateForDestination(index);
    final initialStart = item.startDate != null && !item.startDate!.isBefore(firstDate)
        ? item.startDate!
        : firstDate;
    final initialEnd = item.endDate != null && !item.endDate!.isBefore(initialStart)
        ? item.endDate!
        : initialStart;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      saveText: 'Áp dụng',
      helpText: item.destination.name,
      fieldStartLabelText: 'Ngày đến',
      fieldEndLabelText: 'Ngày rời',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: _primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: _ink,
                ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              headerBackgroundColor: _primary,
              headerForegroundColor: Colors.white,
              rangeSelectionBackgroundColor: _primarySoft,
              rangePickerShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;

    context.read<TripFormProvider>().setDestinationDates(
          index,
          picked.start,
          picked.end,
        );
  }

  Future<void> _pickDestinationDatePart(int index, {required bool pickingStart}) async {
    final form = context.read<TripFormProvider>();
    final item = form.selectedDestinations[index];
    final firstDate = form.firstSelectableDateForDestination(index);
    final currentStart = item.startDate != null && !item.startDate!.isBefore(firstDate)
        ? item.startDate!
        : firstDate;
    final currentEnd = item.endDate != null && !item.endDate!.isBefore(currentStart)
        ? item.endDate!
        : currentStart;
    final initialDate = pickingStart ? currentStart : currentEnd;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: pickingStart ? firstDate : currentStart,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: pickingStart ? 'Chọn ngày đến' : 'Chọn ngày rời',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: _primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: _ink,
                ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              headerBackgroundColor: _primary,
              headerForegroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;

    final nextStart = pickingStart ? picked : currentStart;
    final nextEnd = pickingStart
        ? (currentEnd.isBefore(picked) ? picked : currentEnd)
        : picked;
    context.read<TripFormProvider>().setDestinationDates(index, nextStart, nextEnd);
  }

  void _setTravelGroup(String value) {
    setState(() => _travelGroup = value);
    final form = context.read<TripFormProvider>();
    if (value == 'solo') {
      form.setPeopleCount(1);
    } else if (value == 'couple') {
      form.setPeopleCount(2);
    } else if (form.peopleCount < 3) {
      form.setPeopleCount(3);
    }
  }

  bool get _showsPeoplePicker =>
      _travelGroup == 'family' || _travelGroup == 'friends';

  String get _travelGroupLabel {
    switch (_travelGroup) {
      case 'solo':
        return 'Một mình';
      case 'couple':
        return 'Người yêu';
      case 'family':
        return 'Gia đình';
      default:
        return 'Bạn bè';
    }
  }

  Future<void> _onAnalyzeTrip() async {
    final form = context.read<TripFormProvider>();
    if (!form.canAnalyze || form.departureDate == null || form.returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần chọn điểm đến và ngày đi trước.')),
      );
      return;
    }

    final analysis = await form.analyzeRoute();
    if (!mounted) return;
    if (analysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(form.analyzeError ?? 'Không thể phân tích hành trình.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripRouteAnalysisScreen(
          analysis: analysis,
          departureDate: form.departureDate!,
          returnDate: form.returnDate!,
          peopleCount: form.peopleCount,
          budgetPerPerson: form.budgetPerPerson,
          travelGroup: _travelGroupLabel,
          interests: _interests.toList(),
          specialRequest: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<TripFormProvider>();
    final progress = _progress(form);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: _bg,
              surfaceTintColor: _bg,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: _ink),
              ),
              title: const Text(
                'Lập kế hoạch chuyến đi',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
              ),
              actions: [
                IconButton(
                  tooltip: 'Lịch sử',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TripItineraryHistoryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history_rounded, color: _ink),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 118),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _HeroInterviewCard(progress: progress)
                      .animate()
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.15, end: 0, curve: Curves.easeOutQuad),
                  const SizedBox(height: 18),
                  if (DateTime.now().millisecondsSinceEpoch < 0) _AiBubble(
                    text:
                        'Mình sẽ hỏi nhanh vài câu để hiểu chuyến đi của bạn.',
                  ),
                  const SizedBox(height: 12),
                  _QuestionBlock(
                    step: '01',
                    title: 'Bạn đã có điểm đến chưa?',
                    subtitle: 'Chọn một hoặc nhiều điểm đến cho chuyến đi.',
                    imagePath: 'assets/images/1.jpg',
                    child: Column(
                      children: [
                        if (form.selectedDestinations.isEmpty)
                          _EmptyDestinationAnswer(onPick: _pickDestination)
                        else
                          ...List.generate(
                            form.selectedDestinations.length,
                            (index) => _DestinationAnswerCard(
                              index: index,
                              item: form.selectedDestinations[index],
                              error: form.destinationDateError(index),
                              onPickDate: () => _pickDatesForDestination(index),
                              onPickStartDate: () => _pickDestinationDatePart(index, pickingStart: true),
                              onPickEndDate: () => _pickDestinationDatePart(index, pickingStart: false),
                              onRemove: () {
                                context.read<TripFormProvider>().removeDestinationAt(index);
                              },
                            ),
                          ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _pickDestination,
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: Text(
                            form.selectedDestinations.isEmpty
                                ? 'Chọn điểm đến'
                                : 'Thêm điểm đến khác',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primary,
                            minimumSize: const Size.fromHeight(48),
                            textStyle: const TextStyle(fontWeight: FontWeight.w900),
                            side: const BorderSide(color: _primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fade(delay: 100.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                  const SizedBox(height: 14),
                  _QuestionBlock(
                    step: '02',
                    title: 'Bạn đi với ai?',
                    subtitle: 'Lịch trình sẽ được điều chỉnh theo nhịp đi của nhóm.',
                    imagePath: 'assets/images/2.jpg',
                    child: _ChoiceWrap(
                      values: const ['solo', 'couple', 'family', 'friends'],
                      selected: {_travelGroup},
                      labelFor: (value) {
                        switch (value) {
                          case 'solo':
                            return 'Một mình';
                          case 'couple':
                            return 'Người yêu';
                          case 'family':
                            return 'Gia đình';
                          default:
                            return 'Bạn bè';
                        }
                      },
                      onSelected: _setTravelGroup,
                    ),
                  )
                      .animate()
                      .fade(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                  const SizedBox(height: 14),
                  _QuestionBlock(
                    step: '03',
                    title: 'Bạn thích kiểu du lịch nào?',
                    subtitle: 'Có thể chọn nhiều sở thích.',
                    imagePath: 'assets/images/3.jpg',
                    child: _ChoiceWrap(
                      values: const [
                        'Biển',
                        'Ẩm thực',
                        'Chụp ảnh',
                        'Văn hóa',
                        'Thiên nhiên',
                        'Nightlife',
                        'Nghỉ dưỡng',
                        'Tiết kiệm',
                      ],
                      selected: _interests,
                      multi: true,
                      onSelected: (value) {
                        setState(() {
                          if (_interests.contains(value)) {
                            _interests.remove(value);
                          } else {
                            _interests.add(value);
                          }
                        });
                      },
                    ),
                  )
                      .animate()
                      .fade(delay: 300.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                  const SizedBox(height: 14),
                  _QuestionBlock(
                    step: '04',
                    title: 'Tổng ngân sách chuyến đi',
                    subtitle: 'Đây là ngân sách tổng cho cả nhóm, không phải mỗi người.',
                    trailing: form.budgetLabel,
                    imagePath: 'assets/images/4.jpg',
                    child: BudgetSlider(
                      amount: form.budgetPerPerson,
                      onChanged: (amount) {
                        context.read<TripFormProvider>().setBudgetPerPerson(amount);
                      },
                    ),
                  )
                      .animate()
                      .fade(delay: 400.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                  const SizedBox(height: 14),
                  if (_showsPeoplePicker) ...[
                    _QuestionBlock(
                      step: '05',
                      title: 'Nhóm đi có bao nhiêu người?',
                      subtitle: 'Chỉ cần chọn khi đi gia đình hoặc bạn bè.',
                      child: _Surface(
                        child: PeopleCounter(
                          count: form.peopleCount,
                          onIncrement: () {
                            context.read<TripFormProvider>().incrementPeople();
                          },
                          onDecrement: () {
                            context.read<TripFormProvider>().decrementPeople();
                          },
                        ),
                      ),
                    )
                        .animate()
                        .fade(delay: 500.ms, duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                    const SizedBox(height: 14),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              if (form.canAnalyze)
                BoxShadow(
                  color: _primary.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: form.canAnalyze ? _onAnalyzeTrip : null,
            icon: form.isAnalyzing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              form.isAnalyzing
                  ? 'Đang phân tích...'
                  : form.canAnalyze
                      ? 'Tiếp tục xem tuyến đường'
                      : 'Hoàn tất thông tin để tiếp tục',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFB8C7C0),
              elevation: 0,
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
          ),
        ),
      ),
    );
  }

  double _progress(TripFormProvider form) {
    var completed = 0;
    if (form.selectedDestinations.isNotEmpty) completed++;
    if (form.departureDate != null && form.returnDate != null) completed++;
    if (_travelGroup.isNotEmpty) completed++;
    if (_interests.isNotEmpty) completed++;
    if (form.budgetPerPerson > 0) completed++;
    if (form.peopleCount > 0) completed++;
    return completed / 6;
  }
}


