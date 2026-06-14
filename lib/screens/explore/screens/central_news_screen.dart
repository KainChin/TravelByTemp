import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import 'region_news_body.dart';

/// Màn hình Miền Trung — lọc theo biển xanh, di sản cố kính
class CentralNewsScreen extends StatelessWidget {
  const CentralNewsScreen({super.key});

  static const List<String> _keywords = [
    'miền trung', 'đà nẵng', 'hội an', 'huế', 'quy nhơn', 'phong nha',
    'quảng nam', 'thừa thiên', 'bình định', 'quảng bình', 'nha trang',
    'khánh hòa', 'mỹ sơn', 'non nước', 'bà nà', 'cầu vàng',
  ];

  static const List<DestinationData> _destinations = [
    DestinationData(name: 'Hội An', subtitle: 'Quảng Nam', rating: 4.8, reviewCount: 1200,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Hoi_An_Lanterns.jpg/640px-Hoi_An_Lanterns.jpg'),
    DestinationData(name: 'Huế', subtitle: 'Thừa Thiên Huế', rating: 4.9, reviewCount: 1500,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1e/Hue_Imperial_City.jpg/640px-Hue_Imperial_City.jpg'),
    DestinationData(name: 'Đà Nẵng', subtitle: 'Đà Nẵng', rating: 4.7, reviewCount: 980,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Da_Nang_Beach.jpg/640px-Da_Nang_Beach.jpg'),
    DestinationData(name: 'Quy Nhơn', subtitle: 'Bình Định', rating: 4.7, reviewCount: 750,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/Quy_Nhon_beach.jpg/640px-Quy_Nhon_beach.jpg'),
    DestinationData(name: 'Phong Nha', subtitle: 'Quảng Bình', rating: 4.5, reviewCount: 632,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Phong_Nha_cave.jpg/640px-Phong_Nha_cave.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NewsProvider(),
      child: const RegionNewsBody(
        regionVn: 'Miền Trung',
        regionEn: 'Central Vietnam',
        regionDescription: 'Nơi biển xanh, di sản cổ kính\nvà vẻ đẹp thiên nhiên hòa quyện.',
        heroBannerUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Da_Nang_Beach.jpg/1280px-Da_Nang_Beach.jpg',
        destinations: _destinations,
        filterKeywords: _keywords,
      ),
    );
  }
}