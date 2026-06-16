import 'package:flutter/material.dart';
import '../models/explore_models.dart';
import '../widgets/explore_widgets.dart';

class MienBacScreen extends StatelessWidget {
  const MienBacScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const destinations = [
      DestinationItem(name: 'Hà Nội', tagLine: 'Thủ đô ngàn năm văn hiến', rating: '4.9', reviewCount: '3.5k', imageAsset: 'assets/images/hanoi.png'),
      DestinationItem(name: 'Hạ Long', tagLine: 'Kỳ quan thiên nhiên thế giới', rating: '4.8', reviewCount: '2.8k', imageAsset: 'assets/images/halong.png'),
      DestinationItem(name: 'Sapa', tagLine: 'Thị trấn trong sương', rating: '4.7', reviewCount: '1.9k', imageAsset: 'assets/images/sapa.png'),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: const [
          RegionBanner(
            title: 'Miền Bắc',
            englishTitle: 'Northern Vietnam',
            desc: 'Nơi địa linh nhân kiệt, hùng vĩ núi non và đậm đà bản sắc lịch sử.',
            asset: 'assets/images/banner_bac.png',
          ),
          SectionHeader(title: 'Điểm đến nổi bật tại Miền Bắc'),
          HorizontalDestinationList(items: destinations),
        ],
      ),
    );
  }
}