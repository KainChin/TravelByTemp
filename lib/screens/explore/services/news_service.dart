import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/news_article.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
class NewsService {
  static const String _rssUrl = 'https://vnexpress.net/rss/du-lich.rss';

  static String get _effectiveUrl {
    if (kIsWeb) {
      final encoded = Uri.encodeComponent(_rssUrl);
      return 'https://api.allorigins.win/get?url=$encoded';
    }
    return _rssUrl;
  }
  /// Regex bóc tách URL ảnh thumbnail từ trường <description> của RSS.
  /// VnExpress nhúng ảnh theo dạng: <img src="https://..." hoặc <img src='https://...'
  static final RegExp _imgRegex = RegExp(
    r'''<img[^>]+src=['"]([^'"]+)['"]''',
    caseSensitive: false,
  );

  /// Parse ngày từ chuỗi RFC 822 trong RSS (vd: "Mon, 10 Jun 2024 08:00:00 +0700")
  static DateTime _parseDate(String raw) {
    try {
      return DateTime.parse(raw);
    } catch (_) {
      // Fallback: parse thủ công RFC 822
      final parts = raw.split(' ');
      if (parts.length >= 5) {
        const months = {
          'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
          'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
          'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12',
        };
        final day = parts[1].padLeft(2, '0');
        final month = months[parts[2]] ?? '01';
        final year = parts[3];
        final time = parts[4];
        return DateTime.tryParse('$year-$month-${day}T$time') ?? DateTime.now();
      }
      return DateTime.now();
    }
  }

  /// Gọi HTTP GET đến RSS Feed VnExpress du lịch và parse XML thành List<NewsArticle>.
  /// [allArticles] trả về toàn bộ bài, đã sắp xếp mới nhất lên đầu.
  Future<List<NewsArticle>> fetchAllArticles() async {
    final response = await http.get(
      Uri.parse(_effectiveUrl), // ← đổi _rssUrl thành _effectiveUrl
      headers: {'User-Agent': 'Mozilla/5.0'},
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi tải RSS: ${response.statusCode}');
    }

    // Khi chạy Web, allorigins trả về JSON bọc ngoài → cần lấy phần "contents"
    String xmlString;
    if (kIsWeb) {
      final body = response.body;
      final start = body.indexOf('"contents":"');
      final end = body.lastIndexOf('","status"');
      if (start == -1 || end == -1) throw Exception('Proxy lỗi định dạng');
      xmlString = body
          .substring(start + 12, end)
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\t', '\t')
          .replaceAll(r'\"', '"')
          .replaceAll(r'\\', r'\');
    } else {
      xmlString = response.body; // Android/iOS: dùng thẳng
    }

    final document = XmlDocument.parse(xmlString); // ← đổi response.body thành xmlString
    final items = document.findAllElements('item');

    final articles = items.map((item) {
      final title = item.findElements('title').firstOrNull?.innerText.trim() ?? '';
      final link = item.findElements('link').firstOrNull?.innerText.trim() ?? '';
      final descRaw = item.findElements('description').firstOrNull?.innerText ?? '';
      final pubDateRaw = item.findElements('pubDate').firstOrNull?.innerText ?? '';

      // Regex: bóc URL ảnh đầu tiên trong <description>
      final imgMatch = _imgRegex.firstMatch(descRaw);
      final thumbnailUrl = imgMatch?.group(1) ?? '';

      // Loại bỏ các thẻ HTML khỏi description để lấy text thuần
      final descText = descRaw.replaceAll(RegExp(r'<[^>]*>'), '').trim();

      return NewsArticle(
        title: title,
        description: descText,
        link: link,
        thumbnailUrl: thumbnailUrl,
        pubDate: _parseDate(pubDateRaw),
      );
    }).toList();

    // Sắp xếp mới nhất lên đầu
    articles.sort((a, b) => b.pubDate.compareTo(a.pubDate));
    return articles;
  }
}