import 'package:flutter/material.dart';
import '../models/explore_models.dart';
import '../widgets/explore_widgets.dart';

class MienTrungScreen extends StatelessWidget {
  const MienTrungScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const destinations = [
      DestinationItem(name: 'Đà Nẵng', tagLine: 'Thành phố đáng sống', rating: '4.8', reviewCount: '2.2k', imageAsset: 'assets/images/danang.png'),
      DestinationItem(name: 'Hội An', tagLine: 'Phố cổ đèn lồng hoài niệm', rating: '4.7', reviewCount: '1.8k', imageAsset: 'assets/images/hoian.png'),
      DestinationItem(name: 'Huế', tagLine: 'Cố đô cổ kính Kinh Thành', rating: '4.6', reviewCount: '1.1k', imageAsset: 'assets/images/hue.png'),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: const [
          RegionBanner(
            title: 'Miền Trung',
            englishTitle: 'Central Vietnam',
            desc: 'Nắng gió chan hòa, di sản cổ kính và những bờ biển dài thơ mộng.',
            asset: 'assets/images/banner_tay.jpg',
          ),
          SectionHeader(title: 'Điểm đến nổi bật tại Miền Trung'),
          HorizontalDestinationList(items: destinations),
        ],
      ),
    );
  }
}