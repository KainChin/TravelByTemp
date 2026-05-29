import 'package:flutter/material.dart';
import 'package:assignment/models/destination.dart';

abstract final class MockData {
  static const userName = 'Thu Duc';
  static const userEmail = 'thuduc.nguyen@gmail.com';
  static const userLocation = 'Thu Duc, Sai Gon';

  /// Nhiệt độ giả lập tại vị trí người dùng (°C).
  static const double userTemperatureC = 32.0;

  static const categories = <CategoryItem>[
    CategoryItem(id: 'all', label: 'All', icon: Icons.grid_view_rounded),
    CategoryItem(id: 'beaches', label: 'Beaches', icon: Icons.beach_access),
    CategoryItem(id: 'mountains', label: 'Mountains', icon: Icons.landscape),
    CategoryItem(id: 'waterfalls', label: 'Waterfalls', icon: Icons.water_drop),
    CategoryItem(id: 'camping', label: 'Camping', icon: Icons.forest),
    CategoryItem(id: 'culture', label: 'Culture', icon: Icons.account_balance),
    CategoryItem(id: 'more', label: 'More', icon: Icons.more_horiz),
  ];

  static const destinations = <Destination>[
    Destination(
      id: 'nha-trang',
      name: 'Nha Trang',
      tagline: 'Beach Paradise',
      category: 'Beaches',
      distanceKm: 22,
      rating: 4.8,
      reviewCount: 1200,
      imageUrl:
          'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=600',
      avgTempC: 28,
      climate: DestinationClimate.warm,
    ),
    Destination(
      id: 'da-lat',
      name: 'Đà Lạt',
      tagline: 'Mountain Escape',
      category: 'Mountains',
      distanceKm: 145,
      rating: 4.9,
      reviewCount: 2100,
      imageUrl:
          'https://images.unsplash.com/photo-1583417319070-4a5401d975a2?w=600',
      avgTempC: 18,
      climate: DestinationClimate.cool,
    ),
    Destination(
      id: 'phu-quoc',
      name: 'Phú Quốc',
      tagline: 'Island Retreat',
      category: 'Beaches',
      distanceKm: 280,
      rating: 4.7,
      reviewCount: 980,
      imageUrl:
          'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=600',
      avgTempC: 29,
      climate: DestinationClimate.warm,
    ),
    Destination(
      id: 'ban-gioc',
      name: 'Bản Giốc',
      tagline: 'Waterfall Wonder',
      category: 'Waterfalls',
      distanceKm: 1200,
      rating: 4.6,
      reviewCount: 450,
      imageUrl:
          'https://images.unsplash.com/photo-1432407692369-79c9a5c07085?w=600',
      avgTempC: 22,
      climate: DestinationClimate.cool,
    ),
    Destination(
      id: 'mui-ne',
      name: 'Mũi Né',
      tagline: 'Desert & Sea',
      category: 'Beaches',
      distanceKm: 180,
      rating: 4.5,
      reviewCount: 760,
      imageUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
      avgTempC: 31,
      climate: DestinationClimate.hot,
    ),
    Destination(
      id: 'sapa',
      name: 'Sa Pa',
      tagline: 'Cloud Hunting',
      category: 'Mountains',
      distanceKm: 1350,
      rating: 4.8,
      reviewCount: 890,
      imageUrl:
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600',
      avgTempC: 15,
      climate: DestinationClimate.cold,
    ),
  ];

  static const experiences = <Experience>[
    Experience(
      name: 'Langbiang Peak Trek',
      location: 'Đà Lạt',
      category: 'Nature',
      distanceKm: 145,
      rating: 4.8,
      price: '₫980K / 2N1Đ',
      imageUrl:
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600',
      avgTempC: 18,
    ),
    Experience(
      name: 'Camping under Stars',
      location: 'Đà Lạt',
      category: 'Camping',
      distanceKm: 148,
      rating: 4.7,
      price: '₫650K / 2N1Đ',
      imageUrl:
          'https://images.unsplash.com/photo-1478131143081-80f7f84ca84d?w=600',
      avgTempC: 17,
    ),
    Experience(
      name: 'Street Food Tour',
      location: 'Nha Trang',
      category: 'Food',
      distanceKm: 22,
      rating: 4.9,
      price: '₫50K / pax',
      imageUrl:
          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=600',
      avgTempC: 28,
    ),
    Experience(
      name: 'Ponagar Tower Visit',
      location: 'Nha Trang',
      category: 'Culture',
      distanceKm: 25,
      rating: 4.6,
      price: '₫30K / pax',
      imageUrl:
          'https://images.unsplash.com/photo-1528183429752-a97d0bf99b5a?w=600',
      avgTempC: 28,
    ),
  ];
}
