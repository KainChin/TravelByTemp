// ignore_for_file: unnecessary_library_name
library search_filter_screen;

import 'package:flutter/material.dart';
import 'package:assignment/core/theme/app_colors.dart';
import 'package:assignment/core/widgets/gradient_button.dart';

part 'search_filter/search_filter_widgets.dart';

class DestinationSearchFilter {
  const DestinationSearchFilter({
    required this.maxBudget,
    required this.radiusKm,
    this.category,
  });

  final double maxBudget;
  final double radiusKm;
  final String? category;
}

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  RangeValues _budget = const RangeValues(500, 5000);
  double _radiusKm = 3;
  String? _category;
  String _duration = '2-3 ngày';
  String _destCount = '2 điểm';
  String _travelStyle = 'Bất kỳ';
  String _accommodation = 'Bất kỳ';
  String _rating = 'Bất kỳ';
  final Set<String> _interests = {'Biển', 'Văn hóa', 'Ẩm thực', 'Thiên nhiên'};
  final Map<String, bool> _toggles = {
    'Có hủy miễn phí': true,
    'Ưu đãi & khuyến mãi': true,
    'Phù hợp gia đình': false,
    'Chuyến đi bền vững': false,
  };

  void update(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _card(_budgetSection()),
                  const SizedBox(height: 12),
                  _card(_radiusSection()),
                  const SizedBox(height: 12),
                  _card(_categorySection()),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _card(_chipSection(
                        'Thời gian',
                        Icons.calendar_today,
                        ['Bất kỳ', '1-2 ngày', '2-3 ngày', '4-5 ngày'],
                        _duration,
                        (v) => setState(() => _duration = v),
                      ))),
                      const SizedBox(width: 12),
                      Expanded(child: _card(_chipSection(
                        'Số điểm đến',
                        Icons.place,
                        ['Bất kỳ', '1 điểm', '2 điểm', '3 điểm'],
                        _destCount,
                        (v) => setState(() => _destCount = v),
                      ))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _card(_styleGrid()),
                  const SizedBox(height: 12),
                  _card(_interestsSection()),
                  const SizedBox(height: 12),
                  _card(_accommodationGrid()),
                  const SizedBox(height: 12),
                  _card(_ratingSection()),
                  const SizedBox(height: 12),
                  _card(_otherFilters()),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GradientButton(
            label: 'Áp dụng bộ lọc',
            subtitle: '${_radiusKm.toStringAsFixed(0)} km radius',
            icon: Icons.auto_fix_high,
            onPressed: () => Navigator.pop(
              context,
              DestinationSearchFilter(
                maxBudget: _budget.end * 1000,
                radiusKm: _radiusKm,
                category: _category,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
