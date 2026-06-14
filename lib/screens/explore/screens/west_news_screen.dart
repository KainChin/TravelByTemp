import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import 'region_news_body.dart';

/// Màn hình Miền Tây — lọc theo từ khóa đặc trưng vùng sông nước
class WestNewsScreen extends StatelessWidget {
  const WestNewsScreen({super.key});

  static const List<String> _keywords = [
    'miền tây', 'cần thơ', 'bến tre', 'đồng tháp', 'an giang',
    'phú quốc', 'kiên giang', 'vĩnh long', 'tiền giang', 'hậu giang',
    'sóc trăng', 'bạc liêu', 'cà mau', 'chợ nổi', 'mekong',
  ];

  static const List<DestinationData> _destinations = [
    DestinationData(name: 'Cần Thơ', subtitle: 'Thủ phủ miền Tây', rating: 4.8, reviewCount: 1200,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Can_Tho_Floating_Market.jpg/640px-Can_Tho_Floating_Market.jpg'),
    DestinationData(name: 'Bến Tre', subtitle: 'Xứ dừa xanh', rating: 4.7, reviewCount: 980,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/27/Ben_Tre_river.jpg/640px-Ben_Tre_river.jpg'),
    DestinationData(name: 'Đồng Tháp', subtitle: 'Đất Sen hồng', rating: 4.7, reviewCount: 750,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/27/Dong_Thap_Lotus.jpg/640px-Dong_Thap_Lotus.jpg'),
    DestinationData(name: 'An Giang', subtitle: 'Vùng Bảy Núi', rating: 4.6, reviewCount: 650,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/35/Sam_Mountain.jpg/640px-Sam_Mountain.jpg'),
    DestinationData(name: 'Phú Quốc', subtitle: 'Đảo ngọc', rating: 4.8, reviewCount: 1500,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/Phu_Quoc_Beach.jpg/640px-Phu_Quoc_Beach.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NewsProvider(),
      child: const RegionNewsBody(
        regionVn: 'Miền Tây',
        regionEn: 'Western Vietnam',
        regionDescription: 'Vùng sông nước hiền hòa,\nvườn trái cây trĩu quả và con người thân thiện.',
        heroBannerUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Can_Tho_Floating_Market.jpg/1280px-Can_Tho_Floating_Market.jpg',
        destinations: _destinations,
        filterKeywords: _keywords,
      ),
    );
  }
}