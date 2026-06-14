import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/app_colors.dart';
import '../models/news_article.dart';
import '../providers/news_provider.dart';
import '../widgets/shared_widgets.dart';
import 'location_articles_screen.dart';

/// Data model cho từng điểm đến trong carousel
class DestinationData {
  final String name;
  final String subtitle;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  const DestinationData({
    required this.name, required this.subtitle,
    required this.rating, required this.reviewCount, required this.imageUrl,
  });
}

/// Base widget tái sử dụng cho cả 4 màn hình miền
/// Truyền vào: tên miền, màu hero, ảnh hero, danh sách điểm đến, từ khóa lọc
class RegionNewsBody extends StatefulWidget {
  final String regionVn;
  final String regionEn;
  final String regionDescription;
  final String heroBannerUrl;
  final List<DestinationData> destinations;
  final List<String> filterKeywords; // Từ khóa lọc bài viết theo miền
  final Color heroBannerOverlay;

  const RegionNewsBody({
    super.key,
    required this.regionVn,
    required this.regionEn,
    required this.regionDescription,
    required this.heroBannerUrl,
    required this.destinations,
    required this.filterKeywords,
    this.heroBannerOverlay = const Color(0x80000000),
  });

  @override
  State<RegionNewsBody> createState() => _RegionNewsBodyState();
}

class _RegionNewsBodyState extends State<RegionNewsBody> {
  late NewsProvider _provider;

  /// Hàm lọc bài theo từ khóa đặc trưng của miền (case-insensitive)
  bool _filterByRegion(NewsArticle a) {
    final combined = '${a.title} ${a.description}'.toLowerCase();
    return widget.filterKeywords.any((kw) => combined.contains(kw.toLowerCase()));
  }

  @override
  void initState() {
    super.initState();
    // Dùng addPostFrameCallback để tránh setState trong build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<NewsProvider>();
      _provider.loadInitial(filter: _filterByRegion);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NewsProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // 1. Hero Banner
            _buildHeroBanner(),
            const SizedBox(height: 4),

            // 2. Destinations carousel
            SectionHeader(
              title: 'Điểm đến nổi bật tại ${widget.regionVn}',
              highlightWord: widget.regionVn,
              onViewAll: () {},
            ),
            _buildDestinationCarousel(),

            // 3. Bài viết nổi bật
            SectionHeader(
              title: 'Bài viết nổi bật về ${widget.regionVn}',
              highlightWord: widget.regionVn,
              onViewAll: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => NewsProvider(),
                    child: LocationArticlesScreen(
                      locationName: widget.regionVn,
                      filterKeywords: widget.filterKeywords,
                    ),
                  ),
                ),
              ),
            ),

            // 4. Danh sách bài viết + phân trang
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              )
            else if (provider.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Lỗi: ${provider.error}', style: const TextStyle(color: Colors.red)),
              )
            else ...[
                ...provider.displayedArticles.map((a) => ArticleCardHorizontal(
                  article: a,
                  onTap: () => Navigator.pushNamed(context, '/news-detail', arguments: a),
                  onBookmark: () {},
                )),
                LoadMoreButton(
                  isLoading: provider.isLoadingMore,
                  hasMore: provider.hasMore,
                  onPressed: provider.loadMore,
                ),
              ],
          ],
        );
      },
    );
  }

  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ảnh nền
              CachedNetworkImage(
                imageUrl: widget.heroBannerUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.divider),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.primary.withOpacity(0.3),
                  child: const Icon(Icons.landscape, size: 60, color: Colors.white),
                ),
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.black.withOpacity(0.65), Colors.transparent],
                  ),
                ),
              ),
              // Text overlay
              Positioned(
                left: 16, bottom: 16, right: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.regionVn,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                    Row(children: [
                      const Icon(Icons.location_on, size: 13, color: Colors.white70),
                      const SizedBox(width: 3),
                      Text(widget.regionEn, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ]),
                    const SizedBox(height: 6),
                    Text(widget.regionDescription,
                        style: const TextStyle(fontSize: 12, color: Colors.white70), maxLines: 2),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textPrimary,
                        minimumSize: const Size(120, 34),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Khám phá ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 13),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationCarousel() {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.destinations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final d = widget.destinations[i];
          return DestinationCardVertical(
            name: d.name,
            subtitle: d.subtitle,
            rating: d.rating,
            reviewCount: d.reviewCount,
            imageUrl: d.imageUrl,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => NewsProvider(),
                  child: LocationArticlesScreen(
                    locationName: d.name,
                    filterKeywords: [d.name.toLowerCase()],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}