import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/app_colors.dart';
import '../models/news_article.dart';
import '../widgets/shared_widgets.dart';

/// Màn hình chi tiết bài báo
/// Có hộp Mục lục (Table of Contents) có thể thu gọn / mở rộng
class NewsDetailScreen extends StatefulWidget {
  final NewsArticle article;
  const NewsDetailScreen({super.key, required this.article});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  bool _tocExpanded = true; // Trạng thái mục lục mở/đóng
  bool _isLiked = false;
  int _likeCount = 128;

  /// Tự động sinh mục lục giả từ nội dung bài.
  /// Trong thực tế có thể parse HTML để lấy thẻ <h2>, <h3>.
  List<Map<String, String>> get _tocItems => [
    {'index': '01', 'title': '${widget.article.title.split('–').first.trim()} – Thiên đường'},
    {'index': '02', 'title': 'Thời điểm lý tưởng để du lịch'},
    {'index': '03', 'title': 'Những điểm đến không thể bỏ lỡ'},
    {'index': '04', 'title': 'Ẩm thực – Thiên đường hải sản'},
    {'index': '05', 'title': 'Trải nghiệm thú vị khi đến đây'},
    {'index': '06', 'title': 'Mẹo du lịch hữu ích'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Hero ảnh + AppBar overlay ──
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề
                      Text(widget.article.title, style: AppTextStyles.heading1.copyWith(fontSize: 22, height: 1.3)),
                      const SizedBox(height: 6),
                      Text(widget.article.description,
                          style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5)),
                      const SizedBox(height: 12),
                      // Nguồn + ngày
                      VerifiedSourceRow(source: widget.article.source, pubDate: widget.article.pubDate),
                      const SizedBox(height: 4),
                      Text('5 phút đọc', style: AppTextStyles.caption),
                      const SizedBox(height: 16),

                      // ── Hộp Mục lục có thể thu gọn ──
                      _buildTableOfContents(),
                      const SizedBox(height: 20),

                      // ── Nội dung bài (mock sections) ──
                      ..._buildArticleSections(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // ── Bottom bar: bình luận + like ──
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
        ),
      ),
      actions: [
        _iconCircle(Icons.bookmark_border),
        _iconCircle(Icons.share_outlined),
        _iconCircle(Icons.more_horiz),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: widget.article.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.divider),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.primary.withOpacity(0.2),
                child: const Icon(Icons.image, size: 60, color: Colors.grey),
              ),
            ),
            // Badge NỔI BẬT
            Positioned(
              left: 16, bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tagBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('NỔI BẬT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconCircle(IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 8, bottom: 8),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: AppColors.textPrimary, size: 18),
        onPressed: () {},
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  /// Hộp Mục lục — bấm vào icon mũi tên để thu gọn / mở rộng
  Widget _buildTableOfContents() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _tocExpanded = !_tocExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text('Mục lục',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _tocExpanded ? 0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_up, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          // Items — ẩn/hiện bằng AnimatedSize
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _tocExpanded
                ? Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 3.2,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                mainAxisSpacing: 4,
                crossAxisSpacing: 8,
                children: _tocItems.map((t) => GestureDetector(
                  onTap: () {}, // Scroll đến section tương ứng
                  child: Row(
                    children: [
                      Text('${t['index']} ',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      Expanded(
                        child: Text(t['title']!,
                            style: AppTextStyles.body.copyWith(fontSize: 12),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Sinh các section nội dung bài viết
  List<Widget> _buildArticleSections() {
    return _tocItems.asMap().entries.map((entry) {
      final idx = entry.key;
      final t = entry.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading section (màu xanh)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                children: [
                  TextSpan(text: '${t['index']}  ', style: const TextStyle(color: AppColors.primary)),
                  TextSpan(text: t['title']),
                ],
              ),
            ),
          ),
          // Ảnh minh họa cho 2 section đầu
          if (idx < 2) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: widget.article.thumbnailUrl,
                height: 180, width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(height: 180, color: AppColors.divider),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Đoạn văn nội dung (placeholder)
          Text(
            widget.article.description.isNotEmpty
                ? widget.article.description
                : 'Nội dung đang được cập nhật...',
            style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.7),
          ),
          const SizedBox(height: 20),
        ],
      );
    }).toList();
  }

  /// Bottom bar: input bình luận + like + comment count
  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            // Comment input
            Expanded(
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.centerLeft,
                child: const Text('Viết bình luận...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ),
            ),
            const SizedBox(width: 12),
            // Like button
            GestureDetector(
              onTap: () => setState(() {
                _isLiked = !_isLiked;
                _likeCount += _isLiked ? 1 : -1;
              }),
              child: Row(
                children: [
                  Icon(_isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 22, color: _isLiked ? Colors.red : AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('$_likeCount', style: AppTextStyles.body),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Comment count
            Row(
              children: const [
                Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.textSecondary),
                SizedBox(width: 4),
                Text('32', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}