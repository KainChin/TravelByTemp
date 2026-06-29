import 'package:flutter/material.dart';

enum DestinationClimate { hot, warm, cool, cold }

class Destination {
  const Destination({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.category,
    required this.distanceKm,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.avgTempC,
    required this.climate,
    this.latitude,
    this.longitude,
    this.estimatedCost,
    this.costUnit,
    this.price,
    this.location,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String tagline;
  final String description;
  final String category;
  final double distanceKm;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final double avgTempC;
  final DestinationClimate climate;
  final double? latitude;
  final double? longitude;
  final double? estimatedCost;
  final String? costUnit;
  final String? price;
  final String? location;
  final bool isFavorite;

  Destination copyWith({
    String? id,
    String? name,
    String? tagline,
    String? description,
    String? category,
    double? distanceKm,
    double? rating,
    int? reviewCount,
    String? imageUrl,
    double? avgTempC,
    DestinationClimate? climate,
    double? latitude,
    double? longitude,
    double? estimatedCost,
    String? costUnit,
    String? price,
    String? location,
    bool? isFavorite,
  }) {
    return Destination(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      description: description ?? this.description,
      category: category ?? this.category,
      distanceKm: distanceKm ?? this.distanceKm,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      imageUrl: imageUrl ?? this.imageUrl,
      avgTempC: avgTempC ?? this.avgTempC,
      climate: climate ?? this.climate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      costUnit: costUnit ?? this.costUnit,
      price: price ?? this.price,
      location: location ?? this.location,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  String get distanceLabel => '${distanceKm.toStringAsFixed(0)}km away';

  String get ratingLabel {
    final reviews = reviewCount >= 1000
        ? '${(reviewCount / 1000).toStringAsFixed(1)}k'
        : '$reviewCount';
    return '$rating ($reviews)';
  }

  factory Destination.fromApi(Map<String, dynamic> json) {
    final region = json['region'] as String? ?? 'South';
    final category = json['category'] as String? ?? 'Nature';
    final slug = json['slug'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    final avgTemp = switch (region) {
      'North' => 22.0,
      'Central' => 26.0,
      _ => 28.0,
    };
    final climate = avgTemp >= 30
        ? DestinationClimate.hot
        : avgTemp >= 26
            ? DestinationClimate.warm
            : avgTemp >= 20
                ? DestinationClimate.cool
                : DestinationClimate.cold;

    return Destination(
      id: json['id'] as String,
      name: name,
      tagline: json['province'] as String? ?? category,
      description: json['description'] as String? ?? '',
      category: _mapCategory(category),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      rating: (json['averageRating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (json['totalReviews'] as num?)?.toInt() ?? 0,
      imageUrl: _imageForDestination(
        slug: slug,
        name: name,
        apiImageUrl: json['imageUrl'] as String?,
      ),
      avgTempC: avgTemp,
      climate: climate,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
      costUnit: json['costUnit'] as String?,
      price: _priceLabel(
        (json['estimatedCost'] as num?)?.toDouble(),
        json['costUnit'] as String?,
      ),
      location: json['province'] as String?,
    );
  }

  static String _mapCategory(String apiCategory) {
    return switch (apiCategory.toLowerCase()) {
      'nature' => 'Mountains',
      'cultural' => 'Culture',
      'mountain' => 'Mountains',
      _ => apiCategory,
    };
  }

  static String _imageForDestination({
    required String slug,
    required String name,
    required String? apiImageUrl,
  }) {
    final key = '$slug $name'.toLowerCase();
    for (final entry in _destinationImageQueries.entries) {
      if (key.contains(entry.key)) {
        return _staticDestinationImages[entry.value] ??
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600';
      }
    }
    return apiImageUrl ??
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600';
  }

  static const Map<String, String> _destinationImageQueries = {
    'hue': 'hue-citadel',
    'da-nang': 'da-nang,dragon-bridge',
    'da nang': 'da-nang,dragon-bridge',
    'quy-nhon': 'quy-nhon,beach',
    'quy nhon': 'quy-nhon,beach',
    'phong-nha': 'phong-nha,cave',
    'phong nha': 'phong-nha,cave',
    'ha-noi': 'hanoi,old-quarter',
    'ha noi': 'hanoi,old-quarter',
    'vinh-ha-long': 'ha-long-bay',
    'ha-long': 'ha-long-bay',
    'ha long': 'ha-long-bay',
    'sapa': 'sapa,rice-terrace',
    'ninh-binh': 'ninh-binh,trang-an',
    'ninh binh': 'ninh-binh,trang-an',
    'mu-cang-chai': 'mu-cang-chai,rice-terrace',
    'mu cang chai': 'mu-cang-chai,rice-terrace',
    'phu-quoc': 'phu-quoc,beach',
    'phu quoc': 'phu-quoc,beach',
    'con-dao': 'con-dao,island',
    'con dao': 'con-dao,island',
    'vung-tau': 'vung-tau,beach',
    'vung tau': 'vung-tau,beach',
    'mui-ne': 'mui-ne,sand-dunes',
    'mui ne': 'mui-ne,sand-dunes',
    'da-lat': 'da-lat,pine-forest',
    'da lat': 'da-lat,pine-forest',
    'can-tho': 'can-tho,floating-market',
    'can tho': 'can-tho,floating-market',
    'chau-doc': 'chau-doc,nui-sam',
    'chau doc': 'chau-doc,nui-sam',
    'my-tho': 'my-tho,mekong-river',
    'my tho': 'my-tho,mekong-river',
    'ha-tien': 'ha-tien,beach',
    'ha tien': 'ha-tien,beach',
    'ben-tre': 'ben-tre,coconut-river',
    'ben tre': 'ben-tre,coconut-river',
    'hoi-an': 'hoi-an,lantern',
    'hoi an': 'hoi-an,lantern',
  };

  static const Map<String, String> _staticDestinationImages = {
    'hoi-an,lantern': 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=600',
    'hue-citadel': 'https://images.unsplash.com/photo-1555921015-5532091f6026?w=600',
    'da-nang,dragon-bridge': 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=600',
    'quy-nhon,beach': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
    'phong-nha,cave': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=600',
    'hanoi,old-quarter': 'https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?w=600',
    'ha-long-bay': 'https://images.unsplash.com/photo-1528181304800-259b08848526?w=600',
    'sapa,rice-terrace': 'https://images.unsplash.com/photo-1508193638397-1c4234db14d8?w=600',
    'ninh-binh,trang-an': 'https://images.unsplash.com/photo-1540611025311-01df3cef54b5?w=600',
    'mu-cang-chai,rice-terrace': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600',
    'phu-quoc,beach': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=600',
    'con-dao,island': 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=600',
    'vung-tau,beach': 'https://images.unsplash.com/photo-1526481280693-3bfa7568e0f3?w=600',
    'mui-ne,sand-dunes': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
    'da-lat,pine-forest': 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=600',
    'can-tho,floating-market': 'https://images.unsplash.com/photo-1528181304800-259b08848526?w=600',
    'chau-doc,nui-sam': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600',
    'my-tho,mekong-river': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=600',
    'ha-tien,beach': 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=600',
    'ben-tre,coconut-river': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=600',
  };

  static String? _priceLabel(double? value, String? unit) {
    if (value == null) return null;
    final formatted = value >= 1000000
        ? '${(value / 1000000).toStringAsFixed(1)}M'
        : value.toStringAsFixed(0);
    return '$formatted VND${unit == null ? '' : ' / $unit'}';
  }
}

class Experience {
  const Experience({
    required this.name,
    required this.location,
    required this.category,
    required this.distanceKm,
    required this.rating,
    required this.price,
    required this.imageUrl,
    required this.avgTempC,
  });

  final String name;
  final String location;
  final String category;
  final double distanceKm;
  final double rating;
  final String price;
  final String imageUrl;
  final double avgTempC;
}

class CategoryItem {
  const CategoryItem({
    required this.label,
    required this.icon,
    this.id = '',
  });

  final String id;
  final String label;
  final IconData icon;
}
