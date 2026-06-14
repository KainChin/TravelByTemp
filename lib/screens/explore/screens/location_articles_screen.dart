import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/app_colors.dart';
import '../models/news_article.dart';
import '../providers/news_provider.dart';
import '../widgets/shared_widgets.dart';
import 'news_detail_screen.dart';

/// Màn hình danh sách bài viết theo địa điểm cụ thể (vd: Phú Quốc)
/// Có các tab bộ lọc phụ và hero card nổi bật
class LocationArticlesScreen extends StatefulWidget {
  final String locationName;
  final List<String> filterKeywords;

  const LocationArticlesScreen({
    super.key,
    required this.locationName,
    required this.filterKeywords,
  });

  @override
  State<LocationArticlesScreen> createState() => _LocationArticlesScreenState();
}

class _LocationArticlesScreenState extends State<LocationArticlesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Các tab lọc phụ theo loại bài
  static const List<String> _filterTabs = [
    'Tất cả', 'Điểm đến', 'Kinh nghiệm', 'Ẩm thực', 'Lưu trú', 'Lịch trình',
  ];

  // Mapping tab → từ khóa nhận dạng category trong title
  static const Map<String, List<String>> _categoryKeywords = {
    'Điểm đến': ['địa điểm', 'check-in', 'điểm đến', 'top'],
    'Kinh nghiệm': ['kinh nghiệm', 'hướng dẫn', 'tips', 'mẹo', 'tự túc'],
    'Ẩm thực': ['ẩm thực', 'món ăn', 'quán', 'hải sản', 'đặc sản', 'nhà hàng'],
    'Lưu trú': ['resort', 'khách sạn', 'homestay', 'villa', 'lưu trú', 'hotel'],
    'Lịch trình': ['lịch trình', 'ngày', 'đêm', 'tour', 'itinerary'],
  };

  // Nhãn category hiển thị màu xanh (gán tự động từ title)
  static String _detectCategory(NewsArticle a) {
    final text = a.title.toLowerCase();
    for (final entry in _categoryKeywords.entries) {
      if (entry.value.any((kw) => text.contains(kw))) return entry.key;
    }
    return 'Điểm đến';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterTabs.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().loadInitial(
        filter: (a) {
          final combined = '${a.title} ${a.description}'.toLowerCase();
          return widget.filterKeywords.any((kw) => combined.contains(kw.toLowerCase()));
        },
      );
    });
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
            // ── AppBar tùy chỉnh ──
            _buildAppBar(),
            // ── Filter tabs (Tất cả / Điểm đến / ...) ──
            _buildFilterTabs(),
            // ── Nội dung bài viết ──
            Expanded(child: _buildArticleList()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  children: [
                    const TextSpan(text: 'Bài viết về '),
                    TextSpan(
                      text: widget.locationName,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: Colors.white,
      unselectedLabelColor: AppColors.textSecondary,
      indicator: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      tabs: _filterTabs.map((t) => Tab(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      )).toList(),
      onTap: (_) => setState(() {}), // rebuild để re-filter
    );
  }

  Widget _buildArticleList() {
    return Consumer<NewsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (provider.error != null) {
          return Center(child: Text('Lỗi: ${provider.error}'));
        }

        // Lọc theo tab active
        final activeTab = _filterTabs[_tabController.index];
        final filtered = activeTab == 'Tất cả'
            ? provider.displayedArticles
            : provider.displayedArticles.where((a) {
          final cat = _detectCategory(a);
          return cat == activeTab;
        }).toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Text('Chưa có bài viết nào', style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        return ListView.builder(
          itemCount: filtered.length + 2, // +1 hero, +1 loadmore
          itemBuilder: (_, i) {
            // Bài đầu tiên: hero card lớn
            if (i == 0) return _buildHeroCard(filtered[0]);
            // Các bài còn lại
            if (i <= filtered.length - 1) {
              final article = filtered[i];
              return ArticleCardHorizontal(
                article: article,
                categoryLabel: _detectCategory(article),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => NewsDetailScreen(article: article),
                )),
                onBookmark: () {},
              );
            }
            // Load more button
            return LoadMoreButton(
              isLoading: provider.isLoadingMore,
              hasMore: provider.hasMore,
              onPressed: provider.loadMore,
            );
          },
        );
      },
    );
  }

  /// Hero card nổi bật — bài viết đầu tiên, hiển thị to toàn chiều rộng
  Widget _buildHeroCard(NewsArticle article) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => NewsDetailScreen(article: article),
      )),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: article.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.divider),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.primary.withOpacity(0.2),
                    child: const Icon(Icons.image, size: 60, color: Colors.white),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                    ),
                  ),
                ),
                Positioned(
                  left: 14, right: 14, bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge NỔI BẬT
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.tagBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('NỔI BẬT',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                      const SizedBox(height: 6),
                      Text(article.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(article.description,
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          VerifiedSourceRow(source: article.source, pubDate: article.pubDate),
                          const Spacer(),
                          const Icon(Icons.bookmark_border, color: Colors.white, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}