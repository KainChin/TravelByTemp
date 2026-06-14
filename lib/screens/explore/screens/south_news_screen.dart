import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import 'region_news_body.dart';

/// Màn hình Miền Nam — lọc theo nhịp sống sôi động, hiện đại
class SouthNewsScreen extends StatelessWidget {
  const SouthNewsScreen({super.key});

  static const List<String> _keywords = [
    'miền nam', 'hồ chí minh', 'sài gòn', 'phú quốc', 'cần giờ',
    'đồng tháp mười', 'vũng tàu', 'bình dương', 'đồng nai', 'tây ninh',
    'long an', 'côn đảo', 'bến nghé', 'quận 1', 'thủ đức',
  ];

  static const List<DestinationData> _destinations = [
    DestinationData(name: 'TP. Hồ Chí Minh', subtitle: 'Sài Gòn hoa lệ', rating: 4.8, reviewCount: 2100,
        imageUrl: 'https://picsum.photos/seed/saigon/240/180'),
    DestinationData(name: 'Phú Quốc', subtitle: 'Đảo ngọc', rating: 4.8, reviewCount: 1500,
        imageUrl: 'https://picsum.photos/seed/phuquoc2/240/180'),
    DestinationData(name: 'Cần Giờ', subtitle: 'Rừng ngập mặn', rating: 4.6, reviewCount: 680,
        imageUrl: 'https://picsum.photos/seed/cangio/240/180'),
    DestinationData(name: 'Đồng Tháp Mười', subtitle: 'Vùng đất sen hồng', rating: 4.7, reviewCount: 620,
        imageUrl: 'https://picsum.photos/seed/dongthapmk/240/180'),
    DestinationData(name: 'Vũng Tàu', subtitle: 'Thành phố biển', rating: 4.6, reviewCount: 980,
        imageUrl: 'https://picsum.photos/seed/vungtau/240/180'),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NewsProvider(),
      child: const RegionNewsBody(
        regionVn: 'Miền Nam',
        regionEn: 'Southern Vietnam',
        regionDescription: 'Nhịp sống năng động, hiện đại\nvà thiên nhiên phong phú.',
        heroBannerUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/27/Ho_Chi_Minh_City_Skyline.jpg/1280px-Ho_Chi_Minh_City_Skyline.jpg',
        destinations: _destinations,
        filterKeywords: _keywords,
      ),
    );
  }
}