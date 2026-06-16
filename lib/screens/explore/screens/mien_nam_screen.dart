import 'package:flutter/material.dart';
import '../models/explore_models.dart';
import '../widgets/explore_widgets.dart';

class MienNamScreen extends StatelessWidget {
  const MienNamScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const destinations = [
      DestinationItem(name: 'TP. Hồ Chí Minh', tagLine: 'Hòn ngọc Viễn Đông sầm uất', rating: '4.9', reviewCount: '4.1k', imageAsset: 'assets/images/hcm.jpg'),
      DestinationItem(name: 'Cần Giờ', tagLine: 'Lá phổi xanh của thành phố', rating: '4.5', reviewCount: '530', imageAsset: 'assets/images/cangio.jpg'),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: const [
          RegionBanner(
            title: 'Miền Nam',
            englishTitle: 'Southern Vietnam',
            desc: 'Sầm uất náo nhiệt, năng động và tràn đầy sức sống trẻ.',
            asset: 'assets/images/banner_nam.png',
          ),
          SectionHeader(title: 'Điểm đến nổi bật tại Miền Nam'),
          HorizontalDestinationList(items: destinations),
        ],
      ),
    );
  }
}