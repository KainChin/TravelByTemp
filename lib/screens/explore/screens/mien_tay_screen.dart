import 'package:flutter/material.dart';
import '../models/explore_models.dart';
import '../widgets/explore_widgets.dart';

class MienTayScreen extends StatelessWidget {
  const MienTayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const destinations = [
      DestinationItem(name: 'Cần Thơ', tagLine: 'Thủ phủ miền Tây', rating: '4.8', reviewCount: '1.2k', imageAsset: 'assets/images/cantho.jpg'),
      DestinationItem(name: 'Bến Tre', tagLine: 'Xứ dừa xanh', rating: '4.7', reviewCount: '980', imageAsset: 'assets/images/bentre.jpg'),
      DestinationItem(name: 'Đồng Tháp', tagLine: 'Đất Sen hồng', rating: '4.7', reviewCount: '750', imageAsset: 'assets/images/dongthap.jpg'),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: const [
          RegionBanner(
            title: 'Miền Tây',
            englishTitle: 'Western Vietnam',
            desc: 'Vùng sông nước hiền hòa, vườn trái cây trĩu quả và con người thân thiện.',
            asset: 'assets/images/banner_nam.png',
          ),
          SectionHeader(title: 'Điểm đến nổi bật tại Miền Tây'),
          HorizontalDestinationList(items: destinations),
          SectionHeader(title: 'Bài viết nổi bật về Miền Tây'),
          // Thêm widget bài viết tại đây nếu cần
        ],
      ),
    );
  }
}