import 'package:flutter/material.dart';
// Thêm import này để widget nhận biết được kiểu dữ liệu DestinationItem
import '../models/explore_models.dart';

// Tiêu đề phân mục có nút "Xem tất cả"
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title}); // Đã fix super.key chuẩn Flutter mới
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const Row(
            children: [
              Text('Xem tất cả', style: TextStyle(color: Colors.teal, fontSize: 13)),
              Icon(Icons.arrow_forward_ios, size: 12, color: Colors.teal),
            ],
          ),
        ],
      ),
    );
  }
}

// Card Banner lớn đặc trưng của từng miền
// Card Banner lớn đặc trưng của từng miền
class RegionBanner extends StatelessWidget {
  const RegionBanner({
    super.key,
    required this.title,
    required this.englishTitle,
    required this.desc,
    required this.asset,
  });

  final String title, englishTitle, desc, asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage(asset),
          fit: BoxFit.cover,
          // 🔥 ĐÂY LÀ ĐOẠN KHẮC PHỤC: Ép ảnh căn theo mép trên cùng để không bị nuốt mất chữ thiết kế sẵn
          alignment: Alignment.topCenter,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.85), // Tăng mờ nhẹ một chút ở đáy để nổi bật chữ overlay của Flutter
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(englishTitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            Text(desc, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, height: 1.3)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Khám phá ngay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 10),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Danh sách ngang các điểm đến nổi bật
class HorizontalDestinationList extends StatelessWidget {
  const HorizontalDestinationList({super.key, required this.items});
  final List<DestinationItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: items.length,
        itemBuilder: (context, i) => Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(items[i].imageAsset, height: 115, width: 140, fit: BoxFit.cover),
              ),
              const SizedBox(height: 4),
              Text(items[i].name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(items[i].tagLine, style: const TextStyle(color: Colors.grey, fontSize: 11), overflow: TextOverflow.ellipsis),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 13),
                  const SizedBox(width: 2),
                  Text(items[i].rating, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(' (${items[i].reviewCount})', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}