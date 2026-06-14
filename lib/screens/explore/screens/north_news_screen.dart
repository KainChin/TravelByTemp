import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import 'region_news_body.dart';

/// Màn hình Miền Bắc — lọc theo từ khóa núi non, văn hóa, bốn mùa
class NorthNewsScreen extends StatelessWidget {
  const NorthNewsScreen({super.key});

  static const List<String> _keywords = [
    'miền bắc', 'hà nội', 'hạ long', 'sapa', 'ninh bình', 'mộc châu',
    'quảng ninh', 'lào cai', 'sơn la', 'hòa bình', 'hải phòng',
    'tràng an', 'yên tử', 'tam cốc', 'đồng văn', 'hà giang',
  ];

  static const List<DestinationData> _destinations = [
    DestinationData(name: 'Hà Nội', subtitle: 'Thủ đô ngàn năm văn hiến', rating: 4.8, reviewCount: 1200,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/34/Hoan_Kiem_Lake_Hanoi.jpg/640px-Hoan_Kiem_Lake_Hanoi.jpg'),
    DestinationData(name: 'Hạ Long', subtitle: 'Quảng Ninh', rating: 4.9, reviewCount: 1500,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c7/Ha_Long_Bay.jpg/640px-Ha_Long_Bay.jpg'),
    DestinationData(name: 'Sapa', subtitle: 'Lào Cai', rating: 4.8, reviewCount: 980,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Sapa_rice_terraces.jpg/640px-Sapa_rice_terraces.jpg'),
    DestinationData(name: 'Ninh Bình', subtitle: 'Ninh Bình', rating: 4.7, reviewCount: 750,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Trang_An_Ninh_Binh.jpg/640px-Trang_An_Ninh_Binh.jpg'),
    DestinationData(name: 'Mộc Châu', subtitle: 'Sơn La', rating: 4.6, reviewCount: 632,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/Moc_Chau_flower.jpg/640px-Moc_Chau_flower.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NewsProvider(),
      child: const RegionNewsBody(
        regionVn: 'Miền Bắc',
        regionEn: 'Northern Vietnam',
        regionDescription: 'Vùng đất của núi non hùng vĩ,\nvăn hóa lâu đời và bốn mùa tuyệt sắc.',
        heroBannerUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c7/Ha_Long_Bay.jpg/1280px-Ha_Long_Bay.jpg',
        destinations: _destinations,
        filterKeywords: _keywords,
      ),
    );
  }
}