import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/app_colors.dart';
import '../models/news_article.dart';

// ---------------------------------------------------------------------------
// Widget: Hiển thị tên nguồn báo kèm tích xanh verified
// ---------------------------------------------------------------------------
class VerifiedSourceRow extends StatelessWidget {
  final String source;
  final DateTime pubDate;

  const VerifiedSourceRow({
    super.key,
    required this.source,
    required this.pubDate,
  });

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()} tuần trước';
    if (diff.inDays >= 1) return '${diff.inDays} ngày trước';
    if (diff.inHours >= 1) return '${diff.inHours} giờ trước';
    return '${diff.inMinutes} phút trước';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar nguồn (chữ cái đầu)
        CircleAvatar(
          radius: 10,
          backgroundColor: AppColors.primary,
          child: Text(
            source[0],
            style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(source, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 4),
        // Tích xanh verified
        const Icon(Icons.verified, size: 13, color: AppColors.verified),
        const SizedBox(width: 6),
        const Text('·', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: 6),
        Text(_timeAgo(pubDate), style: AppTextStyles.caption),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Card bài viết dạng ngang (ảnh trái + text phải) — dùng trong danh sách
// ---------------------------------------------------------------------------
class ArticleCardHorizontal extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;
  final VoidCallback onBookmark;
  final String? categoryLabel; // Nhãn category màu xanh (KINH NGHIỆM, ẨM THỰC...)

  const ArticleCardHorizontal({
    super.key,
    required this.article,
    required this.onTap,
    required this.onBookmark,
    this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: article.thumbnailUrl,
                width: 90,
                height: 68,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 90, height: 68,
                  color: AppColors.divider,
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 90, height: 68,
                  color: AppColors.divider,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label category (vd: KINH NGHIỆM)
                  if (categoryLabel != null) ...[
                    Text(
                      categoryLabel!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: AppColors.primary, letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(
                    article.title,
                    style: AppTextStyles.heading2.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.description,
                    style: AppTextStyles.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  VerifiedSourceRow(source: article.source, pubDate: article.pubDate),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Nút bookmark
            GestureDetector(
              onTap: onBookmark,
              child: const Icon(Icons.bookmark_border, size: 20, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Card địa điểm dạng dọc (ảnh trên + tên dưới) — dùng trong scroll ngang
// ---------------------------------------------------------------------------
class DestinationCardVertical extends StatelessWidget {
  final String name;
  final String subtitle;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final VoidCallback onTap;

  const DestinationCardVertical({
    super.key,
    required this.name,
    required this.subtitle,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 120,
                    height: 90,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 120, height: 90, color: AppColors.divider,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 120, height: 90, color: AppColors.divider,
                      child: const Icon(Icons.image),
                    ),
                  ),
                ),
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border, size: 14, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(name, style: AppTextStyles.heading2.copyWith(fontSize: 13)),
            Text(subtitle, style: AppTextStyles.caption),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star, size: 12, color: AppColors.star),
                const SizedBox(width: 2),
                Text(
                  '$rating (${reviewCount >= 1000 ? '${(reviewCount / 1000).toStringAsFixed(1)}k' : reviewCount})',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Nút "Xem thêm bài viết cũ hơn" + loading indicator
// ---------------------------------------------------------------------------
class LoadMoreButton extends StatelessWidget {
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onPressed;

  const LoadMoreButton({
    super.key,
    required this.isLoading,
    required this.hasMore,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('Đã hiển thị tất cả bài viết', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
          : OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Xem thêm bài viết cũ hơn'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Header section (tiêu đề + "Xem tất cả")
// ---------------------------------------------------------------------------
class SectionHeader extends StatelessWidget {
  final String title;
  final String highlightWord; // Từ màu xanh trong title
  final VoidCallback? onViewAll;

  const SectionHeader({
    super.key,
    required this.title,
    required this.highlightWord,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.heading2,
                children: _buildSpans(title, highlightWord),
              ),
            ),
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                children: const [
                  Text('Xem tất cả', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<TextSpan> _buildSpans(String text, String highlight) {
    final idx = text.indexOf(highlight);
    if (idx == -1) return [TextSpan(text: text)];
    return [
      if (idx > 0) TextSpan(text: text.substring(0, idx)),
      TextSpan(text: highlight, style: const TextStyle(color: AppColors.primary)),
      if (idx + highlight.length < text.length) TextSpan(text: text.substring(idx + highlight.length)),
    ];
  }
}