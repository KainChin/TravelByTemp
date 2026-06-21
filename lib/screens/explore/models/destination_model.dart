class DestinationModel {
  final String id;
  final String name;
  final String province;
  final String imageUrl;
  final double rating;
  final bool isFavorite;

  const DestinationModel({
    required this.id,
    required this.name,
    required this.province,
    required this.imageUrl,
    required this.rating,
    this.isFavorite = false,
  });

  DestinationModel copyWith({bool? isFavorite}) => DestinationModel(
    id: id,
    name: name,
    province: province,
    imageUrl: imageUrl,
    rating: rating,
    isFavorite: isFavorite ?? this.isFavorite,
  );
}
