import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/services/api_client.dart';
import '../models/destination_model.dart';
import '../models/region_model.dart';
import '../services/region_service.dart';
import '../widgets/explore_header.dart';
import '../widgets/region_tab_bar.dart';
import '../widgets/region_banner.dart';
import '../widgets/destination_section.dart';
import '../widgets/article_section.dart';
import '../widgets/promo_card.dart';
import 'article_detail_screen.dart';
import 'all_destinations_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    this.onProfileTap,
    this.onSettingsTap,
    this.onLogoutTap,
  });

  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _regionService = RegionService();
  final _scrollController = ScrollController();

  List<RegionModel> _regions = [];
  List<BannerItem> _banners = [];
  RegionType _selectedRegion = RegionType.west;
  bool _isLoading = true;

  RegionModel? get _currentRegion {
    for (final region in _regions) {
      if (region.type == _selectedRegion) return region;
    }
    return _regions.isEmpty ? null : _regions.first;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    try {
      final api = VietaiScope.of(context).api;
      final regions = await _regionService
          .getRegions()
          .timeout(const Duration(seconds: 18));
      var favoriteIds = <String>{};
      
      // Load dynamic location on start!
      unawaited(VietaiScope.of(context).refreshLocationAndWeather());

      try {
        final favorites = await api
            .fetchFavorites()
            .timeout(const Duration(seconds: 5));
        favoriteIds = favorites.map((item) => item.destination.id).toSet();
      } catch (_) {
        // Favorites require login/backend; keep destination list usable.
      }

      final markedRegions = regions
          .map(
            (region) => RegionModel(
              id: region.id,
              name: region.name,
              englishName: region.englishName,
              description: region.description,
              bannerImage: region.bannerImage,
              type: region.type,
              destinations: region.destinations
                  .map((item) => item.copyWith(
                        isFavorite: favoriteIds.contains(item.id),
                      ))
                  .toList(),
              articles: region.articles,
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _regions = markedRegions;
        _isLoading = false;
      });
      _fetchBanners();
    } catch (_) {
      if (mounted) {
        setState(() {
          _regions = [];
          _banners = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchBanners() async {
    if (!mounted) return;
    try {
      final api = VietaiScope.of(context).api;
      final banners = await api
          .fetchBanners(region: _selectedRegion.name)
          .timeout(const Duration(seconds: 5));
      if (mounted) setState(() => _banners = banners);
    } catch (_) {
      if (mounted) setState(() => _banners = []);
    }
  }

  void _onTabChanged(RegionType type) {
    setState(() => _selectedRegion = type);
    _fetchBanners();
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _onFavoriteTap(String destinationId) async {
    DestinationModel? destination;
    for (final item in _currentRegion?.destinations ?? const []) {
      if (item.id == destinationId) {
        destination = item;
        break;
      }
    }
    if (destination == null) return;

    _setFavorite(destinationId, !destination.isFavorite);
    if (!_isUuid(destinationId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demo item only. Open API destinations to save.'),
        ),
      );
      return;
    }

    try {
      final api = VietaiScope.of(context).api;
      if (destination.isFavorite) {
        await api.deleteFavorite(destinationId);
      } else {
        await api.addFavorite(destinationId);
      }
    } catch (e) {
      if (!mounted) return;
      _setFavorite(destinationId, destination.isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot update saved place: $e')),
      );
    }
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  void _setFavorite(String destinationId, bool isFavorite) {
    setState(() {
      _regions = _regions.map((region) {
        if (region.type != _selectedRegion) return region;
        final updated = region.destinations.map((d) {
          if (d.id != destinationId) return d;
          return d.copyWith(isFavorite: isFavorite);
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
        top: false, // Let background image stretch fully if wide
        bottom: false,
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
            child: Center(child: CircularProgressIndicator(color: Color(0xFF1976D2))),
          )
        else if (_currentRegion != null)
          SliverToBoxAdapter(child: _buildContentSection(_currentRegion!)),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Stack(
      children: [
        // Full screen background image for the dashboard
        Positioned.fill(
          child: Image.asset(
            'assets/images/chatAI.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.2), // Subtle dark overlay to keep contrast
          ),
        ),
        // Content Row
        Row(
          children: [
            // Glassmorphic Left Sidebar
            SizedBox(
              width: 280,
              child: _buildSideTabs(),
            ),
            const VerticalDivider(width: 1, color: Colors.white24),
            // Glassmorphic Main Panel
            Expanded(
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.white.withOpacity(0.85), // Soft white overlay to keep content highly readable
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)))
                        : CustomScrollView(
                            controller: _scrollController,
                            slivers: [
                              SliverToBoxAdapter(child: _buildTopSection(wide: true)),
                              if (_currentRegion != null)
                                SliverToBoxAdapter(child: _buildContentSection(_currentRegion!)),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  int get _selectedRegionIndex {
    switch (_selectedRegion) {
      case RegionType.west:
        return 0;
      case RegionType.north:
        return 1;
      case RegionType.central:
        return 2;
      case RegionType.south:
        return 3;
    }
  }

  Widget _buildSideTabs() {
    const tabs = [
      (type: RegionType.west, label: 'Miền Tây', icon: Icons.tsunami_outlined),
      (type: RegionType.north, label: 'Miền Bắc', icon: Icons.landscape_outlined),
      (type: RegionType.central, label: 'Miền Trung', icon: Icons.wb_sunny_outlined),
      (type: RegionType.south, label: 'Miền Nam', icon: Icons.sailing_outlined),
    ];

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3), // Glassy translucent dark background
            border: Border(
              right: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App Logo
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.travel_explore_rounded,
                              color: Color(0xFF1976D2), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'VietAI Travel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    const Text(
                      'VÙNG MIỀN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Vertical sliding tab marker layout
                    Stack(
                      children: [
                        // Sliding Background Marker
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOutCubic,
                          top: _selectedRegionIndex * 52.0,
                          left: 0,
                          right: 0,
                          height: 46,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        // Tab Items
                        Column(
                          children: List.generate(tabs.length, (index) {
                            final tab = tabs[index];
                            final isSelected = _selectedRegion == tab.type;
                            return Container(
                              height: 52,
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: () => _onTabChanged(tab.type),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      Icon(
                                        tab.icon,
                                        size: 20,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white60,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        tab.label,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white60,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Promo Card
                    const PromoCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection({bool wide = false}) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(20, 16, 20, wide ? 16 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExploreHeader(
            onProfileTap: widget.onProfileTap,
            onSettingsTap: widget.onSettingsTap,
            onLogoutTap: widget.onLogoutTap,
          ),
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
                text: 'Khám phá vẻ đẹp của ',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
              ),
              TextSpan(
                text: 'Việt Nam ',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1976D2)),
              ),
              TextSpan(text: '✨', style: TextStyle(fontSize: 20)),
            ],
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Khám phá những vùng đất mới, tạo nên những kỷ niệm khó quên',
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
          RegionBanner(
            region: region,
            banners: _banners,
            onExplore: () {},
          ),
          const SizedBox(height: 24),
          DestinationSection(
            region: region,
            destinations: region.destinations,
            onFavoriteTap: _onFavoriteTap,
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AllDestinationsScreen(
                  region: region,
                  onFavoriteTap: _onFavoriteTap,
                ),
              ),
            ),
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
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
