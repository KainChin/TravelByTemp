// ignore_for_file: use_string_in_part_of_directives

part of saved_screen;

class _SavedHeader extends StatelessWidget {
  const _SavedHeader({
    required this.savedTrips,
    required this.savedPlaces,
    required this.totalDays,
    required this.totalActivities,
    required this.onHomePressed,
    required this.searchController,
    required this.onQuickAction,
  });

  final int savedTrips;
  final int savedPlaces;
  final int totalDays;
  final int totalActivities;
  final VoidCallback onHomePressed;
  final TextEditingController searchController;
  final ValueChanged<String> onQuickAction;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (canPop) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  tooltip: 'Quay lại',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Row(
                children: [
                  const Flexible(
                    child: Text(
                      'Đã lưu',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: onHomePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                icon: const Icon(Icons.home_rounded, size: 18),
                label: const Text(
                  'Trang chủ',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          savedTrips == 0 && savedPlaces == 0
              ? 'Bạn chưa lưu gì. Tạo chuyến đi hoặc lưu địa điểm để AI gợi ý tốt hơn.'
              : 'Tổng hợp $savedTrips hành trình AI và $savedPlaces địa điểm yêu thích của bạn.',
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 4 : 2;
            const gap = 10.0;
            final itemWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: _DashboardMetric(
                    icon: Icons.map_rounded,
                    value: '$savedTrips',
                    label: 'Hành trình',
                    color: const Color(0xFF059669),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _DashboardMetric(
                    icon: Icons.favorite_rounded,
                    value: '$savedPlaces',
                    label: 'Địa điểm',
                    color: const Color(0xFFE11D48),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _DashboardMetric(
                    icon: Icons.calendar_today_rounded,
                    value: '$totalDays',
                    label: 'Tổng ngày',
                    color: const Color(0xFF0D9488),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _DashboardMetric(
                    icon: Icons.event_note_rounded,
                    value: '$totalActivities',
                    label: 'Hoạt động',
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Tìm hành trình, địa điểm đã lưu…',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF)),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Color(0xFF9CA3AF)),
                      onPressed: () => searchController.clear(),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _QuickActionChip(
                label: 'AI tối ưu',
                icon: Icons.auto_awesome_rounded,
                onPressed: () => onQuickAction('AI tối ưu'),
              ),
              const SizedBox(width: 8),
              _QuickActionChip(
                label: 'Tạo chuyến mới',
                icon: Icons.add_rounded,
                onPressed: () => onQuickAction('Tạo chuyến mới'),
              ),
              const SizedBox(width: 8),
              _QuickActionChip(
                label: 'Xuất văn bản',
                icon: Icons.ios_share_rounded,
                onPressed: () => onQuickAction('Xuất văn bản'),
              ),
              const SizedBox(width: 8),
              _QuickActionChip(
                label: 'Khám phá',
                icon: Icons.explore_rounded,
                onPressed: () => onQuickAction('Khám phá'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF16A34A)),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
