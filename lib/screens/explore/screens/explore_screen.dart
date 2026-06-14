import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_colors.dart';
import '../providers/news_provider.dart';
import 'west_news_screen.dart';
import 'north_news_screen.dart';
import 'central_news_screen.dart';
import 'south_news_screen.dart';

/// Màn hình Explore chính — chứa AppBar profile, category chips, và 4 tab miền
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategory = 0; // 0=All, 1=Beaches, ...

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': Icons.explore_rounded},
    {'label': 'Beaches', 'icon': Icons.beach_access},
    {'label': 'Mountains', 'icon': Icons.landscape},
    {'label': 'Waterfalls', 'icon': Icons.water},
    {'label': 'Culture', 'icon': Icons.account_balance},
    {'label': 'Camping', 'icon': Icons.cabin},
    {'label': 'More', 'icon': Icons.more_horiz},
  ];

  final List<Map<String, String>> _regions = [
    {'vn': 'Miền Tây', 'en': 'West'},
    {'vn': 'Miền Bắc', 'en': 'North'},
    {'vn': 'Miền Trung', 'en': 'Central'},
    {'vn': 'Miền Nam', 'en': 'South'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header: Avatar + Tên + Notification ──
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroTitle(),
                    _buildCategoryChips(),
                    _buildRegionTabs(),
                    // Nội dung thay đổi theo tab
                    SizedBox(
                      // Dùng IndexedStack để giữ state khi chuyển tab
                      height: MediaQuery.of(context).size.height * 1.5,
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: const [
                          WestNewsScreen(),
                          NorthNewsScreen(),
                          CentralNewsScreen(),
                          SouthNewsScreen(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 48, height: 48,
              color: AppColors.primaryLight,
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thu Duc',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Row(
                  children: const [
                    Icon(Icons.location_on, size: 13, color: AppColors.primary),
                    SizedBox(width: 2),
                    Text('Ho Chi Minh City, Vietnam',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
          // Notification button
          Stack(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                ),
                child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 20),
              ),
              Positioned(
                top: 8, right: 8,
                child: Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          children: [
            TextSpan(text: 'Explore the Beauty of '),
            TextSpan(text: 'Vietnam', style: TextStyle(color: AppColors.primary)),
            TextSpan(text: ' ✦', style: TextStyle(color: AppColors.primary, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final isActive = i == _selectedCategory;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _categories[i]['icon'],
                      size: 15,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _categories[i]['label'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isActive ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRegionTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        labelPadding: EdgeInsets.zero,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        dividerColor: Colors.transparent,
        tabs: _regions.map((r) => Tab(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(r['vn']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(r['en']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w400)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}