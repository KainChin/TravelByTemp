import 'package:flutter/foundation.dart';
import '../models/news_article.dart';
import '../services/news_service.dart';

class NewsProvider extends ChangeNotifier {
  final NewsService _service = NewsService();

  // Toàn bộ bài đã fetch từ RSS (cache)
  List<NewsArticle> _allArticles = [];

  // Các bài đang hiển thị (đã phân trang)
  List<NewsArticle> _displayedArticles = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  /// Số bài tải mỗi lần (trang đầu + "Xem thêm")
  static const int _pageSize = 5;

  /// Con trỏ phân trang: số bài đã hiển thị hiện tại
  int _currentCount = 0;

  List<NewsArticle> get displayedArticles => _displayedArticles;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;

  /// Còn bài để tải thêm không?
  bool get hasMore => _currentCount < _allArticles.length;

  /// Tải lần đầu (hoặc refresh): fetch RSS rồi hiển thị 5 bài đầu.
  /// [filter]: hàm lọc theo miền hoặc địa điểm (nullable = lấy tất cả)
  Future<void> loadInitial({bool Function(NewsArticle)? filter}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allArticles = await _service.fetchAllArticles();

      // Áp dụng bộ lọc nếu có
      if (filter != null) {
        _allArticles = _allArticles.where(filter).toList();
      }

      _currentCount = 0;
      _displayedArticles = [];
      _appendNextPage();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tải thêm 5 bài cũ hơn, cộng dồn (append) vào danh sách hiện tại.
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    // Giả lập delay nhỏ cho UX mượt mà
    await Future.delayed(const Duration(milliseconds: 400));

    _appendNextPage();

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Nội bộ: cắt slice tiếp theo và append vào _displayedArticles
  void _appendNextPage() {
    final end = (_currentCount + _pageSize).clamp(0, _allArticles.length);
    _displayedArticles = [
      ..._displayedArticles,
      ..._allArticles.sublist(_currentCount, end),
    ];
    _currentCount = end;
  }
}