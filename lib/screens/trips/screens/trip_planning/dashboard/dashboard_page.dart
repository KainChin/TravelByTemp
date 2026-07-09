import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'hero_banner.dart';
import 'quick_action_card.dart';
import 'trip_card.dart';
import 'recommendation_card.dart';
import 'weather_card.dart';
import 'statistics_card.dart';
import 'upcoming_trip_card.dart';
import 'favorite_destination_card.dart';
import 'floating_ai_assistant.dart';

class PremiumDashboardPage extends StatelessWidget {
  final VoidCallback onCreateTrip;
  final VoidCallback onHistory;

  const PremiumDashboardPage({
    super.key,
    required this.onCreateTrip,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // LEFT COLUMN - ~72%
                              Expanded(
                                flex: 72,
                                child: _buildLeftColumn(),
                              ),
                              const SizedBox(width: 32),
                              // RIGHT COLUMN - ~28%
                              Expanded(
                                flex: 28,
                                child: _buildRightColumn(),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLeftColumn(),
                              const SizedBox(height: 32),
                              _buildRightColumn(),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
          
          // Floating AI Assistant
          Positioned(
            bottom: 32,
            right: 32,
            child: FloatingAiAssistant(onTap: onCreateTrip),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero
        HeroBanner(
          imageUrl: 'https://images.unsplash.com/photo-1599839619722-39751411ea63?q=80&w=1000&auto=format&fit=crop', // Halong Bay dummy for now, replace with DB later
          onStartPressed: onCreateTrip,
        ),
        
        const SizedBox(height: 32),
        
        // Quick Actions
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                icon: Icons.add_road_rounded,
                title: 'Tạo hành trình',
                subtitle: 'AI lập kế hoạch',
                onTap: onCreateTrip,
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: QuickActionCard(
                icon: Icons.auto_awesome_rounded,
                title: 'AI Planner',
                subtitle: 'Gợi ý thông minh',
                onTap: onCreateTrip,
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: QuickActionCard(
                icon: Icons.map_rounded,
                title: 'Bản đồ',
                subtitle: 'Khám phá điểm đến',
                onTap: () {},
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: QuickActionCard(
                icon: Icons.history_rounded,
                title: 'Lịch sử',
                subtitle: 'Kế hoạch đã lưu',
                onTap: onHistory,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            ),
          ],
        ),

        const SizedBox(height: 48),

        // Recent Trips Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gần đây',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111111),
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: onHistory,
              child: Text(
                'Xem tất cả →',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981), // Premium Green for action text
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 500.ms),

        const SizedBox(height: 16),

        // Recent Trips List
        Column(
          children: [
            TripCard(
              imageUrl: 'https://images.unsplash.com/photo-1557401622-cfb01eb11c0c?q=80&w=600&auto=format&fit=crop', // Ninh Binh
              destination: 'Lịch trình Du lịch Thực Tế tại Việt Nam',
              dates: '12/03/2024',
              duration: '3 ngày 2 đêm',
              budget: 'Ngân sách thấp',
              weather: 'Gia đình',
              status: 'Thư giãn',
              onTap: () {},
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            TripCard(
              imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?q=80&w=600&auto=format&fit=crop', // Sapa
              destination: 'Hành trình khám phá Tây Bắc',
              dates: '08/02/2024',
              duration: '4 ngày 3 đêm',
              budget: 'Phượt',
              weather: 'Khám phá',
              status: 'Văn hóa',
              onTap: () {},
            ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
          ],
        ),

        const SizedBox(height: 48),

        // Recommendations Header
        Text(
          'Gợi ý dành cho bạn',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111111),
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 800.ms),

        const SizedBox(height: 16),

        // Recommendations Grid/Row
        SizedBox(
          height: 280,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              RecommendationCard(
                imageUrl: 'https://images.unsplash.com/photo-1583417646199-a86477123308?q=80&w=600&auto=format&fit=crop', // Ha Giang
                destination: 'Hà Giang',
                duration: '4 ngày 3 đêm',
                budget: '4.250.000đ',
                onTap: () {},
              ).animate().fadeIn(delay: 900.ms).slideX(begin: 0.1),
              const SizedBox(width: 16),
              RecommendationCard(
                imageUrl: 'https://images.unsplash.com/photo-1596711666838-89c5658e4b3e?q=80&w=600&auto=format&fit=crop', // Da Lat
                destination: 'Đà Lạt',
                duration: '3 ngày 2 đêm',
                budget: '2.890.000đ',
                onTap: () {},
              ).animate().fadeIn(delay: 1000.ms).slideX(begin: 0.1),
              const SizedBox(width: 16),
              RecommendationCard(
                imageUrl: 'https://images.unsplash.com/photo-1549488344-c6a6d634283f?q=80&w=600&auto=format&fit=crop', // Phu Quoc
                destination: 'Phú Quốc',
                duration: '3 ngày 2 đêm',
                budget: '3.750.000đ',
                onTap: () {},
              ).animate().fadeIn(delay: 1100.ms).slideX(begin: 0.1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weather
        const PremiumWeatherCard().animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
        
        const SizedBox(height: 24),
        
        // Stats
        const PremiumStatisticsCard().animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

        const SizedBox(height: 32),

        // Favorites Header
        Text(
          'Điểm đến yêu thích',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111111),
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 500.ms),
        
        const SizedBox(height: 16),

        // Favorites List
        Column(
          children: [
            const FavoriteDestinationCard(
              imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?q=80&w=200&auto=format&fit=crop',
              province: 'Sapa',
              subtitle: 'Lào Cai',
            ).animate().fadeIn(delay: 600.ms),
            const FavoriteDestinationCard(
              imageUrl: 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?q=80&w=200&auto=format&fit=crop',
              province: 'Đà Nẵng',
              subtitle: 'Đà Nẵng',
            ).animate().fadeIn(delay: 700.ms),
            const FavoriteDestinationCard(
              imageUrl: 'https://images.unsplash.com/photo-1596711666838-89c5658e4b3e?q=80&w=200&auto=format&fit=crop',
              province: 'Đà Lạt',
              subtitle: 'Lâm Đồng',
            ).animate().fadeIn(delay: 800.ms),
          ],
        ),

        const SizedBox(height: 32),

        // Upcoming Header
        Text(
          'Kế hoạch sắp tới',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111111),
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 900.ms),
        
        const SizedBox(height: 16),

        // Upcoming List
        Column(
          children: [
            const UpcomingTripCard(
              imageUrl: 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?q=80&w=200&auto=format&fit=crop',
              destination: 'Đà Nẵng - Hội An',
              dateRange: '15/03 - 17/03/2024',
              daysLeft: '3 ngày',
            ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.1),
            const UpcomingTripCard(
              imageUrl: 'https://images.unsplash.com/photo-1557401622-cfb01eb11c0c?q=80&w=200&auto=format&fit=crop',
              destination: 'Ninh Bình',
              dateRange: '22/03 - 24/03/2024',
              daysLeft: '3 ngày',
            ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.1),
            const UpcomingTripCard(
              imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?q=80&w=200&auto=format&fit=crop',
              destination: 'Sapa',
              dateRange: '05/04 - 07/04/2024',
              daysLeft: '3 ngày',
              isLast: true,
            ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.1),
          ],
        ),
      ],
    );
  }
}
