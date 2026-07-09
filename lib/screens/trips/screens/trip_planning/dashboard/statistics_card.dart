import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';

class PremiumStatisticsCard extends StatefulWidget {
  const PremiumStatisticsCard({super.key});

  @override
  State<PremiumStatisticsCard> createState() => _PremiumStatisticsCardState();
}

class _PremiumStatisticsCardState extends State<PremiumStatisticsCard> {
  bool _isLoading = true;
  int _trips = 0;
  int _provinces = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStats();
    });
  }

  Future<void> _fetchStats() async {
    try {
      final api = VietaiScope.of(context).api;
      final summary = await api.fetchProfileSummary();
      if (mounted) {
        setState(() {
          _trips = summary.trips;
          _provinces = summary.savedPlaces; // Use savedPlaces as a proxy for provinces visited
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 20),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(_trips.toString(), 'Chuyến đi'),
                    ),
                    _buildDivider(),
                    Expanded(
                      child: _buildStatItem(_provinces.toString(), 'Số tỉnh đã đi'),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111111),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF888888),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      color: Colors.black.withOpacity(0.05),
    );
  }
}
