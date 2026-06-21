class ArticleModel {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String thumbnailUrl;
  final String source;
  final DateTime publishDate;

  const ArticleModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.thumbnailUrl,
    required this.source,
    required this.publishDate,
  });
}
