import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/destination.dart';
import '../providers/trip_form_provider.dart';
import '../widgets/budget_slider.dart';
import '../widgets/date_field.dart';
import '../widgets/destination_list_item.dart';
import '../widgets/destination_picker_sheet.dart';
import '../widgets/people_counter.dart';

/// Màn hình "Tạo hành trình mới" — tương ứng UI:
/// điểm xuất phát cố định, danh sách điểm đến chọn theo thứ tự,
/// ngày đi/về, số lượng người, ngân sách mỗi người, và nút phân tích.
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
          'Tạo hành trình mới',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text(
              'Lên kế hoạch cho chuyến đi tuyệt vời của bạn',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // --- Điểm xuất phát ---
            const Text('Điểm xuất phát (mặc định)',
                style: TextStyle(fontWeight: FontWeight.w600)),
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

            // --- Danh sách điểm đến ---
            const Text('Danh sách điểm đến',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (form.selectedDestinations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Chưa có điểm đến nào. Bấm "Thêm điểm đến" để bắt đầu.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              )
            else
              ...List.generate(form.selectedDestinations.length, (index) {
                return DestinationListItem(
                  order: index + 1,
                  item: form.selectedDestinations[index],
                  onRemove: () =>
                      context.read<TripFormProvider>().removeDestinationAt(index),
                );
              }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _onAddDestination(context),
              icon: const Icon(Icons.add, color: Color(0xFF0FA958)),
              label: const Text('Thêm điểm đến',
                  style: TextStyle(color: Color(0xFF0FA958))),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: Color(0xFF0FA958)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Ngày đi / Ngày về ---
            Row(
              children: [
                Expanded(
                  child: DateField(
                    label: 'Ngày đi',
                    value: form.departureDate,
                    onPicked: (date) =>
                        context.read<TripFormProvider>().setDepartureDate(date),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DateField(
                    label: 'Ngày về',
                    value: form.returnDate,
                    firstSelectableDate: form.departureDate,
                    onPicked: (date) =>
                        context.read<TripFormProvider>().setReturnDate(date),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Số lượng người ---
            const Text('Số lượng người',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            PeopleCounter(
              count: form.peopleCount,
              onIncrement: () =>
                  context.read<TripFormProvider>().incrementPeople(),
              onDecrement: () =>
                  context.read<TripFormProvider>().decrementPeople(),
            ),
            const SizedBox(height: 24),

            // --- Ngân sách ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ngân sách (mỗi người)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
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
              onChanged: (index) =>
                  context.read<TripFormProvider>().setBudgetTierIndex(index),
            ),
            const SizedBox(height: 24),

            // --- Nút phân tích ---
            ElevatedButton(
              onPressed: form.canAnalyze
                  ? () {
                // TODO: gọi service phân tích hành trình ở đây.
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0FA958),
                disabledBackgroundColor: Colors.grey.shade300,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
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