import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/destination.dart';
import '../providers/trip_form_provider.dart';
import '../widgets/budget_slider.dart';
import '../widgets/destination_picker_sheet.dart';
import '../widgets/people_counter.dart';
import 'trip_itinerary_history_screen.dart';
import 'trip_route_analysis_screen.dart';

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
  static const _bg = Color(0xFFF5F7F4);
  static const _ink = Color(0xFF15221D);
  static const _muted = Color(0xFF6E7A74);
  static const _primary = Color(0xFF008F6A);
  static const _primarySoft = Color(0xFFE6F6F0);
  static const _line = Color(0xFFE2E8E4);
  static const _accent = Color(0xFFFF8A5B);

  String _travelGroup = 'Bạn bè';
  final Set<String> _interests = {'Thiên nhiên', 'Ẩm thực'};
  final TextEditingController _specialRequestController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TripFormProvider>().detectCurrentLocation();
    });
  }

  @override
  void dispose() {
    _specialRequestController.dispose();
    super.dispose();
  }

  Future<void> _pickDestination() async {
    final form = context.read<TripFormProvider>();
    final Destination? picked = await DestinationPickerSheet.show(context);
    if (picked != null) form.addDestination(picked);
  }

  Future<void> _pickTripDates() async {
    final form = context.read<TripFormProvider>();
    final firstDate = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: form.departureDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (start == null || !mounted) return;

    final end = await showDatePicker(
      context: context,
      initialDate: form.returnDate != null && !form.returnDate!.isBefore(start)
          ? form.returnDate!
          : start,
      firstDate: start,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (end == null || !mounted) return;

    context.read<TripFormProvider>().setTripDates(start, end);
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
                  _HeroInterviewCard(progress: progress),
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
                  ),
                  const SizedBox(height: 14),
                  _QuestionBlock(
                    step: '02',
                    title: 'Ngày đi và ngày kết thúc',
                    subtitle: 'Chọn khoảng ngày chung cho toàn bộ chuyến đi.',
                    trailing: form.tripDateError == null
                        ? '${_formatDate(form.departureDate!)} - ${_formatDate(form.returnDate!)}'
                        : null,
                    child: _DateRangeAnswer(
                      start: form.departureDate,
                      end: form.returnDate,
                      error: form.tripDateError,
                      onPick: _pickTripDates,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _QuestionBlock(
                    step: '03',
                    title: 'Bạn đi với ai?',
                    subtitle: 'Lịch trình sẽ được điều chỉnh theo nhịp đi của nhóm.',
                    child: _ChoiceWrap(
                      values: const ['Một mình', 'Người yêu', 'Gia đình', 'Bạn bè'],
                      selected: {_travelGroup},
                      onSelected: (value) => setState(() => _travelGroup = value),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _QuestionBlock(
                    step: '04',
                    title: 'Bạn thích kiểu du lịch nào?',
                    subtitle: 'Có thể chọn nhiều sở thích.',
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
                  ),
                  const SizedBox(height: 14),
                  _QuestionBlock(
                    step: '05',
                    title: 'Ngân sách mỗi người',
                    subtitle: 'Kéo nhanh hoặc nhập số tiền cụ thể.',
                    trailing: form.budgetLabel,
                    child: BudgetSlider(
                      amount: form.budgetPerPerson,
                      onChanged: (amount) {
                        context.read<TripFormProvider>().setBudgetPerPerson(amount);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _QuestionBlock(
                    step: '06',
                    title: 'Nhóm đi có bao nhiêu người?',
                    subtitle: 'Chi phí sẽ được tính theo số người.',
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
                  ),
                  const SizedBox(height: 14),
                  _QuestionBlock(
                    step: '07',
                    title: 'Yêu cầu đặc biệt',
                    subtitle: 'Ví dụ: tránh đi bộ nhiều, có trẻ em, ăn chay, tránh mưa.',
                    child: TextField(
                      controller: _specialRequestController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Ghi chú thêm cho chuyến đi...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: _line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: _line),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: SizedBox(
          height: 56,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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

class _HeroInterviewCard extends StatelessWidget {
  const _HeroInterviewCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _AiInterviewViewState._primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xE80A241E), Color(0x66152F28)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 15, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Lập hành trình',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 84),
                const Text(
                  'Kể mình nghe\nchuyến đi bạn muốn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1.06,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Chọn điểm đến, thời gian, ngân sách và nhóm đi để app gợi ý tuyến đường phù hợp.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  const _AiBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _AiInterviewViewState._primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.auto_awesome,
            size: 18,
            color: _AiInterviewViewState._primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: _AiInterviewViewState._line),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: _AiInterviewViewState._ink,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionBlock extends StatelessWidget {
  const _QuestionBlock({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String step;
  final String title;
  final String subtitle;
  final Widget child;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _AiInterviewViewState._primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  step,
                  style: const TextStyle(
                    color: _AiInterviewViewState._primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _AiInterviewViewState._ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _AiInterviewViewState._muted,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(
                    color: _AiInterviewViewState._primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.values,
    required this.selected,
    required this.onSelected,
    this.multi = false,
  });

  final List<String> values;
  final Set<String> selected;
  final ValueChanged<String> onSelected;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final isSelected = selected.contains(value);
        return ChoiceChip(
          label: Text(value),
          selected: isSelected,
          showCheckmark: multi,
          selectedColor: _AiInterviewViewState._primarySoft,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isSelected
                ? _AiInterviewViewState._primary
                : _AiInterviewViewState._line,
          ),
          labelStyle: TextStyle(
            color: isSelected
                ? _AiInterviewViewState._primary
                : _AiInterviewViewState._ink,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          onSelected: (_) => onSelected(value),
        );
      }).toList(),
    );
  }
}

class _EmptyDestinationAnswer extends StatelessWidget {
  const _EmptyDestinationAnswer({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _AiInterviewViewState._line),
        ),
        child: const Row(
          children: [
            Icon(Icons.travel_explore, color: _AiInterviewViewState._primary, size: 30),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Chọn điểm đến hoặc thêm nhiều chặng để tối ưu tuyến đường.',
                style: TextStyle(
                  color: _AiInterviewViewState._ink,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRangeAnswer extends StatelessWidget {
  const _DateRangeAnswer({
    required this.start,
    required this.end,
    required this.error,
    required this.onPick,
  });

  final DateTime? start;
  final DateTime? end;
  final String? error;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final hasDates = start != null && end != null;
    final label = hasDates
        ? '${_formatDate(start!)} - ${_formatDate(end!)}'
        : 'Chọn ngày đi / ngày kết thúc';

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: error == null
                ? _AiInterviewViewState._line
                : _AiInterviewViewState._accent,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.date_range_outlined,
              color: _AiInterviewViewState._primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _AiInterviewViewState._ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(Icons.edit_calendar_outlined, color: _AiInterviewViewState._muted),
          ],
        ),
      ),
    );
  }
}

class _DestinationAnswerCard extends StatelessWidget {
  const _DestinationAnswerCard({
    required this.index,
    required this.item,
    required this.onRemove,
  });

  final int index;
  final SelectedDestination item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _AiInterviewViewState._line,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _AiInterviewViewState._primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: _AiInterviewViewState._primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.destination.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AiInterviewViewState._ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      item.destination.region,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AiInterviewViewState._muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _AiInterviewViewState._line),
      ),
      child: child,
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month';
}
