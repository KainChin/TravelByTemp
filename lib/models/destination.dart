import 'package:flutter/material.dart';

enum DestinationClimate { hot, warm, cool, cold }

class Destination {
  const Destination({
    required this.id,
    required this.name,
    required this.tagline,
    required this.category,
    required this.distanceKm,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.avgTempC,
    required this.climate,
    this.latitude,
    this.longitude,
    this.price,
    this.location,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String tagline;
  final String category;
  final double distanceKm;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final double avgTempC;
  final DestinationClimate climate;
  final double? latitude;
  final double? longitude;
  final String? price;
  final String? location;
  final bool isFavorite;

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
    if (key.contains('da-lat') || key.contains('đà lạt') || key.contains('da lat')) {
      return 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=600';
    }
    return apiImageUrl ??
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600';
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
