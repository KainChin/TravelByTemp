import 'package:flutter/material.dart';
import '../models/region_model.dart';
import '../services/region_service.dart';
import '../widgets/explore_header.dart';
import '../widgets/region_tab_bar.dart';
import '../widgets/region_banner.dart';
import '../widgets/destination_section.dart';
import '../widgets/article_section.dart';
import 'article_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _regionService = RegionService();
  final _scrollController = ScrollController();

  List<RegionModel> _regions = [];
  RegionType _selectedRegion = RegionType.central;
  bool _isLoading = true;

  RegionModel? get _currentRegion =>
      _regions.isEmpty ? null : _regions.firstWhere((r) => r.type == _selectedRegion);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final regions = await _regionService.getRegions();
    if (mounted) setState(() { _regions = regions; _isLoading = false; });
  }

  void _onTabChanged(RegionType type) {
    setState(() => _selectedRegion = type);
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _onFavoriteTap(String destinationId) {
    setState(() {
      _regions = _regions.map((region) {
        if (region.type != _selectedRegion) return region;
        final updated = region.destinations.map((d) {
          if (d.id != destinationId) return d;
          return d.copyWith(isFavorite: !d.isFavorite);
        }).toList();
        return RegionModel(
          id: region.id,
          name: region.name,
          englishName: region.englishName,
          description: region.description,
          bannerImage: region.bannerImage,
          type: region.type,
          destinations: updated,
          articles: region.articles,
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 720;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(child: _buildTopSection()),
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: Color(0xFF16A34A))),
          )
        else if (_currentRegion != null)
          SliverToBoxAdapter(child: _buildContentSection(_currentRegion!)),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        SizedBox(width: 260, child: _buildSideTabs()),
        const VerticalDivider(width: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))
              : CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildTopSection(wide: true)),
              if (_currentRegion != null)
                SliverToBoxAdapter(child: _buildContentSection(_currentRegion!)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSideTabs() {
    const tabs = [
      (type: RegionType.west, label: 'Miền Tây', sub: 'West'),
      (type: RegionType.north, label: 'Miền Bắc', sub: 'North'),
      (type: RegionType.central, label: 'Miền Trung', sub: 'Central'),
      (type: RegionType.south, label: 'Miền Nam', sub: 'South'),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Text('Vùng miền',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          ),
          ...tabs.map((tab) {
            final isSelected = _selectedRegion == tab.type;
            return GestureDetector(
              onTap: () => _onTabChanged(tab.type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFECFDF5) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border.all(color: const Color(0xFF16A34A)) : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tab.label,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF374151))),
                          Text(tab.sub,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF))),
                        ],
                      ),
                    ),
                    if (isSelected) const Icon(Icons.chevron_right, color: Color(0xFF16A34A), size: 18),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopSection({bool wide = false}) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20, 16, 20, wide ? 16 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExploreHeader(),
          const SizedBox(height: 20),
          _buildTitle(),
          const SizedBox(height: 20),
          if (!wide) ...[
            RegionTabBar(selectedRegion: _selectedRegion, onRegionChanged: _onTabChanged),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Explore the Beauty of ',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
              ),
              TextSpan(
                text: 'Vietnam ',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
              ),
              TextSpan(text: '✨', style: TextStyle(fontSize: 20)),
            ],
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Discover new places, create unforgettable memories',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildContentSection(RegionModel region) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          RegionBanner(region: region, onExplore: () {}),
          const SizedBox(height: 24),
          DestinationSection(
            region: region,
            destinations: region.destinations,
            onFavoriteTap: _onFavoriteTap,
            onViewAll: () {},
          ),
          const SizedBox(height: 28),
          ArticleSection(
            region: region,
            articles: region.articles,
            onArticleTap: (article) => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article)),
            ),
            onViewAll: () {},
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
