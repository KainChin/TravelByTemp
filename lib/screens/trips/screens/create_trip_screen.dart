import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/destination.dart';
import '../providers/trip_form_provider.dart';
import '../widgets/budget_slider.dart';
import '../widgets/destination_list_item.dart';
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
      child: const _CreateTripView(),
    );
  }
}

class _CreateTripView extends StatefulWidget {
  const _CreateTripView();

  @override
  State<_CreateTripView> createState() => _CreateTripViewState();
}

class _CreateTripViewState extends State<_CreateTripView> {
  static const _bg = Color(0xFFF5F7F4);
  static const _ink = Color(0xFF15221D);
  static const _primary = Color(0xFF008F6A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TripFormProvider>().detectCurrentLocation();
    });
  }

  Future<void> _onAddDestination(BuildContext context) async {
    final form = context.read<TripFormProvider>();
    final Destination? picked = await DestinationPickerSheet.show(context);
    if (picked != null) form.addDestination(picked);
  }

  Future<void> _onAnalyzeTrip(BuildContext context) async {
    final form = context.read<TripFormProvider>();
    if (!form.canAnalyze ||
        form.departureDate == null ||
        form.returnDate == null) {
      return;
    }
    final analysis = await form.analyzeRoute();
    if (!context.mounted) return;
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
                'Tạo hành trình',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
              ),
              actions: [
                IconButton(
                  tooltip: 'Lịch sử lịch trình',
                  icon: const Icon(Icons.history_rounded, color: _ink),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TripItineraryHistoryScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _IntroCard(destinationCount: form.selectedDestinations.length),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Điểm xuất phát',
                    subtitle: form.isLocating ? 'Đang lấy vị trí hiện tại...' : 'Có thể cập nhật lại bằng GPS',
                  ),
                  const SizedBox(height: 10),
                  _DepartureCard(form: form),
                  const SizedBox(height: 22),
                  _SectionHeader(
                    title: 'Các chặng du lịch',
                    subtitle: 'Mỗi chặng cần có ngày bắt đầu và kết thúc',
                    trailing: form.selectedDestinations.isEmpty
                        ? null
                        : '${form.selectedDestinations.length} điểm',
                  ),
                  const SizedBox(height: 10),
                  if (form.selectedDestinations.isEmpty)
                    _EmptyDestinationCard(onTap: () => _onAddDestination(context))
                  else
                    ...List.generate(form.selectedDestinations.length, (index) {
                      return DestinationListItem(
                        order: index + 1,
                        item: form.selectedDestinations[index],
                        firstStartDate: form.firstSelectableDateForDestination(index),
                        dateError: form.destinationDateError(index),
                        onStartDatePicked: (date) {
                          context
                              .read<TripFormProvider>()
                              .setDestinationStartDate(index, date);
                        },
                        onEndDatePicked: (date) {
                          context
                              .read<TripFormProvider>()
                              .setDestinationEndDate(index, date);
                        },
                        onRemove: () {
                          context.read<TripFormProvider>().removeDestinationAt(index);
                        },
                      );
                    }),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _onAddDestination(context),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Thêm điểm đến'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      minimumSize: const Size.fromHeight(50),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      side: const BorderSide(color: _primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _SectionHeader(
                    title: 'Nhóm đi',
                    subtitle: 'Số người tham gia chuyến đi',
                  ),
                  const SizedBox(height: 10),
                  _SurfaceCard(
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
                  const SizedBox(height: 22),
                  _SectionHeader(
                    title: 'Ngân sách',
                    subtitle: 'Nhập tay hoặc kéo nhanh theo mức phù hợp',
                    trailing: form.budgetLabel,
                  ),
                  const SizedBox(height: 10),
                  BudgetSlider(
                    amount: form.budgetPerPerson,
                    onChanged: (amount) {
                      context.read<TripFormProvider>().setBudgetPerPerson(amount);
                    },
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
            onPressed: form.canAnalyze ? () => _onAnalyzeTrip(context) : null,
            icon: form.isAnalyzing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.route_outlined),
            label: Text(form.isAnalyzing ? 'Đang phân tích...' : 'Phân tích hành trình'),
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
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.destinationCount});

  final int destinationCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF05251D),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Multi-stop planner',
                  style: TextStyle(
                    color: Color(0xFFB9F2D8),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tối ưu tuyến đi trước khi tạo lịch trình',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  destinationCount == 0
                      ? 'Thêm điểm đến đầu tiên để bắt đầu.'
                      : '$destinationCount điểm đến đã được chọn.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.map_outlined, color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }
}

class _DepartureCard extends StatelessWidget {
  const _DepartureCard({required this.form});

  final TripFormProvider form;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F4E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.my_location_rounded, color: Color(0xFF008F6A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  form.departureLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF15221D),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${form.departure.latitude.toStringAsFixed(5)}, ${form.departure.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(
                    color: Color(0xFF6E7A74),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (form.locationError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    form.locationError!,
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Lấy vị trí hiện tại',
            onPressed: form.isLocating
                ? null
                : () => context.read<TripFormProvider>().detectCurrentLocation(),
            icon: form.isLocating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, color: Color(0xFF008F6A)),
          ),
        ],
      ),
    );
  }
}

class _EmptyDestinationCard extends StatelessWidget {
  const _EmptyDestinationCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8E4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_location_alt_outlined, color: Color(0xFF008F6A), size: 30),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thêm điểm đến đầu tiên',
                    style: TextStyle(
                      color: Color(0xFF15221D),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Bạn có thể chọn nhiều tỉnh/thành và sắp xếp theo thứ tự di chuyển.',
                    style: TextStyle(
                      color: Color(0xFF6E7A74),
                      height: 1.35,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E4)),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF15221D),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF6E7A74),
                  fontSize: 12,
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
              color: Color(0xFF008F6A),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    );
  }
}
