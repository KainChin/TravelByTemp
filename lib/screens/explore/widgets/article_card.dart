import 'package:flutter/material.dart';
import '../models/article_model.dart';

class ArticleCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback? onTap;
  final VoidCallback? onBookmarkTap;

  const ArticleCard({
    super.key,
    required this.article,
    this.onTap,
    this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(url: article.thumbnailUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    article.summary,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _SourceChip(source: article.source),
                      const SizedBox(width: 6),
                      const Text('·', style: TextStyle(color: Color(0xFF9CA3AF))),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(article.publishDate),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onBookmarkTap,
                        child: const Icon(
                          Icons.bookmark_border,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return '1 ngày trước';
    return '$diff ngày trước';
  }
}

class _Thumbnail extends StatelessWidget {
  final String url;
  const _Thumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 90,
        height: 90,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE5E7EB)),
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String source;
  const _SourceChip({required this.source});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFF16A34A),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.public, size: 10, color: Colors.white),
        ),
        const SizedBox(width: 4),
        Text(
          source,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(width: 2),
        const Icon(Icons.verified, size: 11, color: Color(0xFF16A34A)),
      ],
    );
  }
}
