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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TripFormProvider>().detectCurrentLocation();
      }
    });
  }

  Future<void> _onAddDestination(BuildContext context) async {
    final form = context.read<TripFormProvider>();
    final Destination? picked = await DestinationPickerSheet.show(context);
    if (picked != null) {
      form.addDestination(picked);
    }
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
        SnackBar(content: Text(form.analyzeError ?? 'Cannot analyze route.')),
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
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAF8),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Tạo hành trình',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(
            tooltip: 'Lịch sử lịch trình',
            icon: const Icon(Icons.history, color: Colors.black),
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B7D4B), Color(0xFF0FA958)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x330B7D4B),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.travel_explore, color: Colors.white, size: 30),
                  SizedBox(height: 12),
                  Text(
                    'Lên tuyến đi nhiều điểm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Chọn từng điểm đến, ngày ở lại và ngân sách. AI sẽ phân tích tuyến đường trước khi tạo lịch trình.',
                    style: TextStyle(color: Color(0xFFE5FFF1), height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionLabel(title: 'Điểm xuất phát'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8E4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF0FA958)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          form.departureLabel,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${form.departure.latitude.toStringAsFixed(5)}, ${form.departure.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                            color: Color(0xFF647067),
                            fontSize: 12,
                          ),
                        ),
                        if (form.locationError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            form.locationError!,
                            style: const TextStyle(
                              color: Color(0xFFB42318),
                              fontSize: 12,
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
                        : () => context
                            .read<TripFormProvider>()
                            .detectCurrentLocation(),
                    icon: form.isLocating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, color: Color(0xFF0FA958)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionLabel(title: 'Các chặng du lịch'),
                if (form.selectedDestinations.isNotEmpty)
                  Text(
                    '${form.selectedDestinations.length} điểm',
                    style: const TextStyle(
                      color: Color(0xFF0FA958),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (form.selectedDestinations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Chưa có điểm đến. Hãy thêm ít nhất một điểm.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              )
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
              icon: const Icon(Icons.add, color: Color(0xFF0FA958)),
              label: const Text(
                'Thêm điểm đến',
                style: TextStyle(color: Color(0xFF0FA958)),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: Color(0xFF0FA958)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionLabel(title: 'Số người'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8E4)),
              ),
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionLabel(title: 'Ngân sách'),
                Text(
                  form.budgetLabel,
                  style: const TextStyle(
                    color: Color(0xFF0FA958),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            BudgetSlider(
              amount: form.budgetPerPerson,
              onChanged: (amount) {
                context.read<TripFormProvider>().setBudgetPerPerson(amount);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: form.canAnalyze ? () => _onAnalyzeTrip(context) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0FA958),
                disabledBackgroundColor: Colors.grey.shade300,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: form.isAnalyzing
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'PHÂN TÍCH HÀNH TRÌNH',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 16,
        color: Color(0xFF1B1F1C),
      ),
    );
  }
}
