import 'package:flutter/material.dart';
import 'package:assignment/core/theme/app_colors.dart';
import 'package:assignment/core/widgets/gradient_button.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  RangeValues _budget = const RangeValues(500, 5000);
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
            subtitle: '35 chuyến đi phù hợp',
            icon: Icons.auto_fix_high,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          const Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Bộ lọc tìm kiếm',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                  ],
                ),
                Text(
                  'Tùy chỉnh chuyến đi theo ý bạn',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(() {
              _budget = const RangeValues(500, 5000);
              _duration = 'Bất kỳ';
              _destCount = 'Bất kỳ';
            }),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Đặt lại', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ],
    );
  }

  Widget _budgetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Ngân sách', Icons.account_balance_wallet_outlined),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.cardBorder,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.1),
          ),
          child: RangeSlider(
            values: _budget,
            min: 500,
            max: 5000,
            divisions: 9,
            onChanged: (v) => setState(() => _budget = v),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('₫500K', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text(
              '₫${_budget.start.round()}K - ₫${_budget.end.round()}K+ / người',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const Text('₫5,000,000+', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _chipSection(
    String title,
    IconData icon,
    List<String> options,
    String selected,
    ValueChanged<String> onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title, icon),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((o) {
            final sel = selected == o;
            return GestureDetector(
              onTap: () => onSelect(o),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.cardBorder,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      o,
                      style: TextStyle(
                        fontSize: 11,
                        color: sel ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (sel) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.check, size: 14, color: AppColors.primary),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _styleGrid() {
    final styles = [
      ('Bất kỳ', Icons.explore, true),
      ('Thư giãn', Icons.beach_access, false),
      ('Khám phá', Icons.landscape, false),
      ('Văn hóa', Icons.temple_buddhist, false),
      ('Phiêu lưu', Icons.hiking, false),
      ('Ẩm thực', Icons.restaurant, false),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Phong cách du lịch', Icons.star_outline),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: styles.length,
            itemBuilder: (_, i) {
              final (label, icon, _) = styles[i];
              final sel = _travelStyle == label;
              return GestureDetector(
                onTap: () => setState(() => _travelStyle = label),
                child: Container(
                  width: 72,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.cardBorder,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: sel ? AppColors.primary : AppColors.textSecondary),
                      const SizedBox(height: 4),
                      Text(label, style: TextStyle(fontSize: 10, color: sel ? AppColors.primary : null)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _interestsSection() {
    final tags = [
      'Biển', 'Núi', 'Thác nước', 'Cắm trại', 'Văn hóa',
      'Ẩm thực', 'Thiên nhiên', 'Lịch sử', 'Chụp ảnh', 'Mua sắm',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Sở thích', Icons.favorite_border),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((t) {
            final sel = _interests.contains(t);
            return FilterChip(
              label: Text(t, style: TextStyle(fontSize: 12, color: sel ? AppColors.primary : null)),
              selected: sel,
              onSelected: (v) => setState(() {
                if (v) {
                  _interests.add(t);
                } else {
                  _interests.remove(t);
                }
              }),
              selectedColor: AppColors.primaryLight,
              checkmarkColor: AppColors.primary,
              side: BorderSide(color: sel ? AppColors.primary : AppColors.cardBorder),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _accommodationGrid() {
    final items = ['Bất kỳ', 'Khách sạn', 'Resort', 'Homestay', 'Hostel'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Loại hình lưu trú', Icons.hotel),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: items.map((l) {
            final sel = _accommodation == l;
            final purple = l == 'Bất kỳ';
            return ChoiceChip(
              label: Text(l, style: const TextStyle(fontSize: 12)),
              selected: sel,
              onSelected: (_) => setState(() => _accommodation = l),
              selectedColor: purple
                  ? AppColors.accentPurple.withValues(alpha: 0.15)
                  : AppColors.primaryLight,
              side: BorderSide(
                color: sel
                    ? (purple ? AppColors.accentPurple : AppColors.primary)
                    : AppColors.cardBorder,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _ratingSection() {
    final opts = ['Bất kỳ', '3.0+', '4.0+', '4.5+', '5.0+'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Đánh giá tối thiểu', Icons.star),
        const SizedBox(height: 12),
        Row(
          children: opts.map((o) {
            final sel = _rating == o;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _rating = o),
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: sel ? AppColors.primary : AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    o,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: sel ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _otherFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Bộ lọc khác', Icons.tune),
        const SizedBox(height: 12),
        ..._toggles.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                  Switch(
                    value: e.value,
                    onChanged: (v) => setState(() => _toggles[e.key] = v),
                    activeTrackColor: AppColors.primary,
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
