import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/destination.dart';
import '../providers/trip_form_provider.dart';
import '../widgets/budget_slider.dart';
import '../widgets/date_field.dart';
import '../widgets/destination_list_item.dart';
import '../widgets/destination_picker_sheet.dart';
import '../widgets/people_counter.dart';
import 'trip_itinerary_result_screen.dart';
import 'trip_itinerary_history_screen.dart';

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

class _CreateTripView extends StatelessWidget {
  const _CreateTripView();

  Future<void> _onAddDestination(BuildContext context) async {
    final form = context.read<TripFormProvider>();
    final Destination? picked = await DestinationPickerSheet.show(context);
    if (picked != null) {
      form.addDestination(picked);
    }
  }

  Future<void> _onAnalyzeTrip(BuildContext context) async {
    final form = context.read<TripFormProvider>();
    final result = await form.analyzeTrip();
    if (!context.mounted) return;

    if (result == null) {
      final message = form.analyzeError ?? 'Cannot generate itinerary.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripItineraryResultScreen(
          response: result.response,
          itinerary: result.itinerary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<TripFormProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Create trip',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(
            tooltip: 'Itinerary history',
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
            const Text(
              'Plan your next trip with AI.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              'Departure point',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3FBF6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF0FA958)),
                  const SizedBox(width: 8),
                  Text(form.departurePoint),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Destinations',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (form.selectedDestinations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No destinations yet. Add at least one destination.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              )
            else
              ...List.generate(form.selectedDestinations.length, (index) {
                return DestinationListItem(
                  order: index + 1,
                  item: form.selectedDestinations[index],
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
                'Add destination',
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
            Row(
              children: [
                Expanded(
                  child: DateField(
                    label: 'Start date',
                    value: form.departureDate,
                    onPicked: (date) {
                      context.read<TripFormProvider>().setDepartureDate(date);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DateField(
                    label: 'End date',
                    value: form.returnDate,
                    firstSelectableDate: form.departureDate,
                    onPicked: (date) {
                      context.read<TripFormProvider>().setReturnDate(date);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'People',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            PeopleCounter(
              count: form.peopleCount,
              onIncrement: () {
                context.read<TripFormProvider>().incrementPeople();
              },
              onDecrement: () {
                context.read<TripFormProvider>().decrementPeople();
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Budget per person',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
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
              tierIndex: form.budgetTierIndex,
              onChanged: (index) {
                context.read<TripFormProvider>().setBudgetTierIndex(index);
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
                      'GENERATE ITINERARY',
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
