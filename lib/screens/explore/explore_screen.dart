import 'package:flutter/material.dart';
// Import 4 sub-screens từ folder con screens/
import 'screens/mien_tay_screen.dart';
import 'screens/mien_bac_screen.dart';
import 'screens/mien_trung_screen.dart';
import 'screens/mien_nam_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int selectedCategoryIndex = 0;
  int selectedRegionIndex = 0; // Quản lý tab Miền hiện tại

  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.explore, 'label': 'All'},
    {'icon': Icons.beach_access, 'label': 'Beaches'},
    {'icon': Icons.terrain, 'label': 'Mountains'},
    {'icon': Icons.waterfall_chart, 'label': 'Waterfalls'},
    {'icon': Icons.account_balance, 'label': 'Culture'},
    {'icon': Icons.gite, 'label': 'Camping'},
  ];

  // Khởi tạo các view tương ứng với 4 file vừa tách
  final List<Widget> _regionViews = const [
    MienTayScreen(),
    MienBacScreen(),
    MienTrungScreen(),
    MienNamScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildMainTitle(),
            _buildCategoryList(),
            _buildRegionTabs(),

            // Phần hiển thị nội dung riêng của từng miền
            Expanded(
              child: IndexedStack(
                index: selectedRegionIndex,
                children: _regionViews,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundImage: AssetImage('assets/images/hcm.jpg'),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thu Duc', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: const [
                  Icon(Icons.location_on, size: 14, color: Colors.teal),
                  SizedBox(width: 4),
                  Text('Ho Chi Minh City, Vietnam', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey),
                ],
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
            child: const Icon(Icons.notifications_none, color: Colors.black87),
          )
        ],
      ),
    );
  }

  Widget _buildMainTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Explore the Beauty of ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Vietnam', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
              const SizedBox(width: 4),
              Icon(Icons.auto_awesome, color: Colors.teal.shade300, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Discover new places, create unforgettable memories', style: TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => selectedCategoryIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? Colors.teal.shade700 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(categories[index]['icon'], size: 16, color: isSelected ? Colors.white : Colors.black87),
                  const SizedBox(width: 6),
                  Text(categories[index]['label'], style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRegionTabs() {
    final List<List<String>> tabs = [
      ['Miền Tây', 'West'],
      ['Miền Bắc', 'North'],
      ['Miền Trung', 'Central'],
      ['Miền Nam', 'South']
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Container(
        height: 45,
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: List.generate(tabs.length, (index) {
            bool isSelected = selectedRegionIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedRegionIndex = index),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(tabs[index][0], style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.teal.shade800 : Colors.grey.shade600)),
                      Text(tabs[index][1], style: TextStyle(fontSize: 10, color: isSelected ? Colors.teal.shade600 : Colors.grey.shade400)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}