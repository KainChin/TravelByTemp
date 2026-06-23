import 'destination_model.dart';
import 'article_model.dart';

enum RegionType { west, north, central, south }

class RegionModel {
  final String id;
  final String name;
  final String englishName;
  final String description;
  final String bannerImage;
  final RegionType type;
  final List<DestinationModel> destinations;
  final List<ArticleModel> articles;

  const RegionModel({
    required this.id,
    required this.name,
    required this.englishName,
    required this.description,
    required this.bannerImage,
    required this.type,
    required this.destinations,
    required this.articles,
  });
}
