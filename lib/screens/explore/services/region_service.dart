import '../models/region_model.dart';
import 'destination_service.dart';
import 'article_service.dart';

class RegionService {
  final DestinationService _destinationService = DestinationService();
  final ArticleService _articleService = ArticleService();

  // TODO: GET /api/regions
  Future<List<RegionModel>> getRegions() async {
    final regions = <RegionModel>[];
    for (final type in RegionType.values) {
      final destinations = await _destinationService.getDestinationsByRegion(type);
      final articles = await _articleService.getArticlesByRegion(type);
      regions.add(RegionModel(
        id: type.name,
        name: _nameOf(type),
        englishName: _englishNameOf(type),
        description: _descriptionOf(type),
        bannerImage: _bannerImageOf(type),
        type: type,
        destinations: destinations,
        articles: articles,
      ));
    }
    return regions;
  }

  static String _nameOf(RegionType t) => switch (t) {
        RegionType.west => 'Miền Tây',
        RegionType.north => 'Miền Bắc',
        RegionType.central => 'Miền Trung',
        RegionType.south => 'Miền Nam',
      };

  static String _englishNameOf(RegionType t) => switch (t) {
        RegionType.west => 'Western Vietnam',
        RegionType.north => 'Northern Vietnam',
        RegionType.central => 'Central Vietnam',
        RegionType.south => 'Southern Vietnam',
      };

  static String _descriptionOf(RegionType t) => switch (t) {
        RegionType.west => 'Vùng đất sông nước trù phú với văn hóa miệt vườn và ẩm thực đặc sắc.',
        RegionType.north => 'Nơi lưu giữ hồn cốt ngàn năm văn hiến với thiên nhiên hùng vĩ và phong phú.',
        RegionType.central => 'Nơi biển xanh, di sản cổ kính và vẻ đẹp thiên nhiên hòa quyện.',
        RegionType.south => 'Vùng đất năng động với biển đảo tuyệt đẹp và văn hóa đa dạng.',
      };

  static String _bannerImageOf(RegionType t) => switch (t) {
        RegionType.west => 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=800',
        RegionType.north => 'https://images.unsplash.com/photo-1528181304800-259b08848526?w=800',
        RegionType.central => 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=800',
        RegionType.south => 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800',
      };
}
