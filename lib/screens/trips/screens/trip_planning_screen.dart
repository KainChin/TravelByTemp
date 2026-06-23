import 'package:flutter/material.dart';

import 'create_trip_screen.dart';

/// Màn hình "Trips" hiển thị danh sách hành trình của người dùng.
/// Bấm nút "Tạo hành trình mới" sẽ điều hướng sang [CreateTripScreen].
class TripPlanningScreen extends StatelessWidget {
  const TripPlanningScreen({super.key});

  void _openCreateTrip(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTripScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Hành trình của tôi',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.luggage_outlined,
                          size: 64, color: Color(0xFFBDBDBD)),
                      const SizedBox(height: 16),
                      const Text(
                        'Chưa có hành trình nào',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bắt đầu lên kế hoạch cho chuyến đi tiếp theo của bạn.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton.icon(
                onPressed: () => _openCreateTrip(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Tạo hành trình mới',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0FA958),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}