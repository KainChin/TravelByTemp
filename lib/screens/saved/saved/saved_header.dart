// ignore_for_file: use_string_in_part_of_directives
part of saved_screen;

class _SavedHeader extends StatelessWidget {
  const _SavedHeader({
    required this.savedTrips,
    required this.savedPlaces,
    required this.onHomePressed,
    required this.searchController,
    required this.onQuickAction,
  });

  final int savedTrips;
  final int savedPlaces;
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
                  tooltip: 'Back',
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
                      'Saved',
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
                  'Home',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Your AI trips, favorite places, and smart travel signals in one workspace.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 5 : 2;
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
                    label: 'Trips',
                    color: const Color(0xFF059669),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _DashboardMetric(
                    icon: Icons.favorite_rounded,
                    value: '$savedPlaces',
                    label: 'Places',
                    color: const Color(0xFFE11D48),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: const _DashboardMetric(
                    icon: Icons.savings_rounded,
                    value: '15%',
                    label: 'Savings',
                    color: Color(0xFFF97316),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: const _DashboardMetric(
                    icon: Icons.auto_awesome_rounded,
                    value: '92',
                    label: 'AI score',
                    color: Color(0xFF0D9488),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: const _DashboardMetric(
                    icon: Icons.star_rounded,
                    value: '4.8',
                    label: 'Rating',
                    color: Color(0xFFF59E0B),
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
              hintText: 'Search trips, destinations, AI notes...',
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
                label: 'AI optimize',
                icon: Icons.auto_awesome_rounded,
                onPressed: () => onQuickAction('AI optimize'),
              ),
              const SizedBox(width: 8),
              _QuickActionChip(
                label: 'New trip',
                icon: Icons.add_rounded,
                onPressed: () => onQuickAction('New trip'),
              ),
              const SizedBox(width: 8),
              _QuickActionChip(
                label: 'Export PDF',
                icon: Icons.ios_share_rounded,
                onPressed: () => onQuickAction('Export PDF'),
              ),
              const SizedBox(width: 8),
              _QuickActionChip(
                label: 'Explore',
                icon: Icons.explore_rounded,
                onPressed: () => onQuickAction('Explore'),
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
