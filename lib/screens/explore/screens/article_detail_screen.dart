import 'package:flutter/material.dart';
import 'package:assignment/core/widgets/safe_network_image.dart';
import '../models/article_model.dart';

class ArticleDetailScreen extends StatelessWidget {
  final ArticleModel article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _CoverAppBar(article: article),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MetaRow(article: article),
                  const Divider(height: 28, color: Color(0xFFF3F4F6)),
                  Text(
                    article.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF374151),
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverAppBar extends StatelessWidget {
  final ArticleModel article;
  const _CoverAppBar({required this.article});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Colors.white,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF111827)),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            SafeNetworkImage(
              url: article.thumbnailUrl,
              fit: BoxFit.cover,
              source: 'article detail thumbnail',
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x88000000)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final ArticleModel article;
  const _MetaRow({required this.article});

  @override
  Widget build(BuildContext context) {
    final diff = DateTime.now().difference(article.publishDate).inDays;
    final dateLabel = diff == 0 ? 'Hôm nay' : '$diff ngày trước';

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFF1976D2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.public, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Text(
          article.source,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.verified, size: 14, color: Color(0xFF1976D2)),
        const SizedBox(width: 8),
        const Text('·', style: TextStyle(color: Color(0xFF9CA3AF))),
        const SizedBox(width: 8),
        Text(
          dateLabel,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
      ],
    );
  }
}
