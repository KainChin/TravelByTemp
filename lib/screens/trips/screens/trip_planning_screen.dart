import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/map_section.dart';

class TripPlanningScreen extends StatefulWidget {
  const TripPlanningScreen({super.key});

  @override
  State<TripPlanningScreen> createState() => _TripPlanningScreenState();
}

class _TripPlanningScreenState extends State<TripPlanningScreen> {
  LatLng? _searchedLocation; // Lưu tọa độ tìm được từ thanh Search
  final TextEditingController _searchController = TextEditingController();
  final String _googleApiKey = "AIzaSyC-sZpjiTqOpPHQ0D3KuavSgKOHm9KPPjA";

  // Hàm chuyển đổi Tên địa danh thành Tọa độ (Geocoding API)
  Future<void> _searchPlace(String text) async {
    if (text.isEmpty) return;

    final url = "https://maps.googleapis.com/maps/api/geocode/json?address=$text&key=$_googleApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final loc = data['results'][0]['geometry']['location'];
        setState(() {
          _searchedLocation = LatLng(loc['lat'], loc['lng']);
        });
        // Ẩn bàn phím sau khi search
        FocusScope.of(context).unfocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy địa điểm này")),
        );
      }
    } catch (e) {
      print("Lỗi Search: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF2ECC71);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Search Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Plan Your Trip", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const Text("Where do you want to go?", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 20),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onSubmitted: (value) => _searchPlace(value), // Nhấn Enter để tìm
                    decoration: InputDecoration(
                      hintText: "Search destination...",
                      prefixIcon: Icon(Icons.location_on_outlined, color: themeColor),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _searchPlace(_searchController.text),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F7F5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Current Location Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.radio_button_checked, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Current location", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text("Your current GPS position", style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text("Change", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader("Popular destinations", "See all", themeColor),

            // Popular Destinations List (Placeholder)
            SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildDestCard("Đà Lạt", "6h 35m", "https://picsum.photos/id/10/200/300"),
                  _buildDestCard("Nha Trang", "8h 20m", "https://picsum.photos/id/11/200/300"),
                  _buildDestCard("Phú Quốc", "1h 15m", "https://picsum.photos/id/12/200/300"),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader("Map & Route", "View full map", themeColor),

            // Map Section - Truyền destination tìm kiếm được vào đây
            MapSection(destination: _searchedLocation),

            // Info Card bên dưới map
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network('https://picsum.photos/80', width: 80, height: 80, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("Selected Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  SizedBox(width: 4),
                                  Icon(Icons.check_circle, color: Colors.teal, size: 16),
                                ],
                              ),
                              Text("Vietnam", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text("Ready to explore?", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.favorite_border, color: Colors.black),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () {},
                      child: const Text("Confirm Destination", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            // AI Planner Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)]),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("AI Trip Planner ✨", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text("Get a personalized itinerary based on your budget...", style: TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                    Image.network('https://cdn-icons-png.flaticon.com/512/4712/4712035.png', width: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(action, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDestCard(String name, String time, String img) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(img, height: 90, width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}