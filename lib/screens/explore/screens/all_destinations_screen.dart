import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:assignment/core/widgets/safe_network_image.dart';
import '../models/region_model.dart';
import '../models/destination_model.dart';
import '../widgets/destination_card.dart';

class AllDestinationsScreen extends StatefulWidget {
  final RegionModel region;
  final void Function(String destinationId) onFavoriteTap;

  const AllDestinationsScreen({
    super.key,
    required this.region,
    required this.onFavoriteTap,
  });

  @override
  State<AllDestinationsScreen> createState() => _AllDestinationsScreenState();
}

class _AllDestinationsScreenState extends State<AllDestinationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<DestinationModel> _filteredDestinations = [];

  @override
  void initState() {
    super.initState();
    _filteredDestinations = widget.region.destinations;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredDestinations = widget.region.destinations;
      } else {
        _filteredDestinations = widget.region.destinations.where((item) {
          return item.name.toLowerCase().contains(query) ||
              item.province.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 720;
    // Responsive grid column calculation
    final columns = isWide ? 4 : 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          // Premium Glassmorphic Header Banner
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1976D2),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  SafeNetworkImage(
                    url: widget.region.bannerImage,
                    fit: BoxFit.cover,
                    fallback: Container(color: const Color(0xFF1976D2)),
                    source: 'all destinations banner image',
                  ),
                  // Dark linear overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black87,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Title Text inside Banner
                  Positioned(
                    left: 20,
                    bottom: 24,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              color: Colors.white.withOpacity(0.15),
                              child: const Text(
                                'Điểm Đến Nổi Bật',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.region.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm điểm đến tại ${widget.region.name}...',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1976D2)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Color(0xFF9CA3AF)),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // Grid List of Destinations
          if (_filteredDestinations.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off_rounded, size: 48, color: Color(0xFF9CA3AF)),
                    SizedBox(height: 12),
                    Text(
                      'Không tìm thấy điểm đến phù hợp',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 0.78 : 0.71,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final destination = _filteredDestinations[index];
                    return _StaggeredGridItem(
                      index: index,
                      child: DestinationCard(
                        destination: destination,
                        width: double.infinity, // Fill cell width
                        onFavoriteTap: () {
                          widget.onFavoriteTap(destination.id);
                          setState(() {
                            _filteredDestinations[index] = destination.copyWith(
                              isFavorite: !destination.isFavorite,
                            );
                          });
                        },
                      ),
                    );
                  },
                  childCount: _filteredDestinations.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StaggeredGridItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggeredGridItem({required this.index, required this.child});

  @override
  State<_StaggeredGridItem> createState() => _StaggeredGridItemState();
}

class _StaggeredGridItemState extends State<_StaggeredGridItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    // Staggered trigger based on item index
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
      ),
    );
  }
}
