/// Model đại diện cho một bài báo từ RSS Feed VnExpress
class NewsArticle {
  final String title;
  final String description;
  final String link;
  final String thumbnailUrl;
  final DateTime pubDate;
  final String source; // Tên nguồn: VnExpress Travel, Traveloka...
  final String category; // Điểm đến / Kinh nghiệm / Ẩm thực / Lưu trú / Lịch trình

  const NewsArticle({
    required this.title,
    required this.description,
    required this.link,
    required this.thumbnailUrl,
    required this.pubDate,
    this.source = 'VnExpress Travel',
    this.category = 'Điểm đến',
  });

  /// Tạo bản sao với category được gán lại
  NewsArticle copyWith({String? category}) {
    return NewsArticle(
      title: title,
      description: description,
      link: link,
      thumbnailUrl: thumbnailUrl,
      pubDate: pubDate,
      source: source,
      category: category ?? this.category,
    );
  }
}