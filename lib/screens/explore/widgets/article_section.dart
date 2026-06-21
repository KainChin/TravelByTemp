import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../models/region_model.dart';
import 'article_card.dart';

class ArticleSection extends StatelessWidget {
  final RegionModel region;
  final List<ArticleModel> articles;
  final void Function(ArticleModel article)? onArticleTap;
  final VoidCallback? onViewAll;

  const ArticleSection({
    super.key,
    required this.region,
    required this.articles,
    this.onArticleTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Bài viết nổi bật về ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    TextSpan(
                      text: region.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: const Row(
                children: [
                  Text(
                    'Xem tất cả',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios, size: 11, color: Color(0xFF16A34A)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...articles.map(
              (article) => ArticleCard(
            article: article,
            onTap: () => onArticleTap?.call(article),
          ),
        ),
      ],
    );
  }
}
