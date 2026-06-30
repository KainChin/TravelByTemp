import '../models/article_model.dart';
import '../models/region_model.dart';

class ArticleService {
  // TODO: Replace with real API calls
  // GET /api/articles?region={regionId}
  // GET /api/articles/{id}

  Future<List<ArticleModel>> getArticlesByRegion(RegionType region) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _fakeData[region] ?? [];
  }

  Future<ArticleModel?> getArticleById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (final list in _fakeData.values) {
      for (final article in list) {
        if (article.id == id) return article;
      }
    }
    return null;
  }

  static final Map<RegionType, List<ArticleModel>> _fakeData = {
    RegionType.central: [
      ArticleModel(
        id: 'a1',
        title: 'Đà Nẵng – Thành phố đáng sống bên bờ biển',
        summary: 'Khám phá những địa điểm không thể bỏ lỡ tại thành phố năng động và hiện đại.',
        content: '''Đà Nẵng được mệnh danh là thành phố đáng sống nhất Việt Nam với bờ biển tuyệt đẹp trải dài hàng chục kilomét. Nơi đây hội tụ đủ những điều kiện lý tưởng cho một chuyến du lịch hoàn hảo: biển xanh, cát trắng, núi non hùng vĩ và ẩm thực phong phú.

**Cầu Vàng – Biểu tượng mới của Đà Nẵng**

Cầu Vàng trên đỉnh Bà Nà Hills là công trình kiến trúc độc đáo thu hút hàng triệu du khách mỗi năm. Cây cầu dài 150m được đỡ bởi hai bàn tay khổng lồ, tạo nên khung cảnh siêu thực giữa mây trời.

**Bãi biển Mỹ Khê**

Một trong những bãi biển đẹp nhất Đông Nam Á với làn nước trong xanh và bãi cát mịn màng. Đây là điểm đến lý tưởng để thư giãn và tham gia các hoạt động thể thao nước.

**Ẩm thực Đà Nẵng**

Mì Quảng, bánh xèo, bánh tráng cuốn thịt heo là những món ăn đặc trưng không thể bỏ qua khi đến Đà Nẵng.''',
        thumbnailUrl: 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=400',
        source: 'VnExpress Travel',
        publishDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ArticleModel(
        id: 'a2',
        title: 'Hội An – Phố cổ đẹp nhất châu Á về đêm',
        summary: 'Dạo bước trên những con phố cổ, thả hồn vào ánh đèn lồng lung linh và ẩm thực đặc sắc.',
        content: '''Hội An là đô thị cổ được UNESCO công nhận là Di sản Văn hóa Thế giới. Mỗi buổi tối, phố cổ lung linh ánh đèn lồng tạo nên khung cảnh huyền ảo, lãng mạn khó quên.

**Phố đèn lồng**

Những chiếc đèn lồng đủ màu sắc treo khắp các con phố tạo nên bức tranh đêm rực rỡ. Đây là biểu tượng văn hóa đặc trưng của Hội An.

**Ẩm thực Hội An**

Cao Lầu, Mì Quảng, Bánh Mì Hội An nổi tiếng là những món ăn không thể bỏ qua. Chợ đêm Hội An là nơi tuyệt vời để thưởng thức ẩm thực địa phương.''',
        thumbnailUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400',
        source: 'Traveloka',
        publishDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
      ArticleModel(
        id: 'a3',
        title: 'Huế – Cố đô ngàn năm văn hiến',
        summary: 'Khám phá kinh thành Huế với những di tích lịch sử vô giá và ẩm thực cung đình tinh tế.',
        content: '''Huế từng là kinh đô của triều Nguyễn, vương triều phong kiến cuối cùng của Việt Nam. Nơi đây lưu giữ nhiều di sản văn hóa vô giá được UNESCO công nhận.

**Đại Nội Huế**

Hoàng thành Huế là quần thể kiến trúc cung đình đồ sộ với hàng trăm công trình lịch sử. Đây là nơi sinh sống và làm việc của các vị vua triều Nguyễn.''',
        thumbnailUrl: 'https://images.unsplash.com/photo-1555921015-5532091f6026?w=400',
        source: 'Booking.com',
        publishDate: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ],
    RegionType.north: [
      ArticleModel(
        id: 'a4',
        title: 'Hạ Long – Kỳ quan thiên nhiên thế giới',
        summary: 'Vịnh Hạ Long với hàng nghìn đảo đá vôi tạo nên cảnh quan hùng vĩ không nơi nào có được.',
        content: '''Vịnh Hạ Long được UNESCO công nhận là Di sản Thiên nhiên Thế giới. Với hơn 1.600 hòn đảo lớn nhỏ, nơi đây tạo nên khung cảnh thiên nhiên kỳ vĩ, hùng tráng.''',
        thumbnailUrl: 'https://images.unsplash.com/photo-1528181304800-259b08848526?w=400',
        source: 'VnExpress Travel',
        publishDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ArticleModel(
        id: 'a5',
        title: 'Sapa – Mùa vàng trên ruộng bậc thang',
        summary: 'Tháng 9 và 10 là thời điểm đẹp nhất để chiêm ngưỡng ruộng bậc thang vàng óng tại Sapa.',
        content: '''Sapa là thị trấn miền núi nằm ở độ cao 1.600m so với mực nước biển. Khí hậu mát mẻ quanh năm và cảnh quan thiên nhiên tuyệt đẹp khiến nơi đây trở thành điểm đến hàng đầu tại miền Bắc.''',
        thumbnailUrl: 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=400',
        source: 'Traveloka',
        publishDate: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ],
    RegionType.south: [
      ArticleModel(
        id: 'a6',
        title: 'Phú Quốc – Đảo Ngọc thiên đường biển',
        summary: 'Hòn đảo lớn nhất Việt Nam với bãi biển nguyên sơ và hải sản tươi ngon.',
        content: '''Phú Quốc được mệnh danh là Đảo Ngọc của Việt Nam với bãi biển đẹp hoang sơ, nước biển trong xanh và đa dạng hải sản. Nơi đây đang trở thành điểm đến du lịch đẳng cấp quốc tế.''',
        thumbnailUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=400',
        source: 'VnExpress Travel',
        publishDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ArticleModel(
        id: 'a7',
        title: 'Đà Lạt – Thành phố ngàn hoa bốn mùa',
        summary: 'Khám phá thành phố mộng mơ với khí hậu mát mẻ và vườn hoa rực rỡ.',
        content: '''Đà Lạt nằm trên cao nguyên Lâm Viên ở độ cao 1.500m, nơi bốn mùa mát mẻ và hoa nở rực rỡ quanh năm. Thành phố này là điểm đến lý tưởng cho những ai muốn thoát khỏi cái nóng oi ả của miền Nam.''',
        thumbnailUrl: 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=400',
        source: 'Booking.com',
        publishDate: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ],
    RegionType.west: [
      ArticleModel(
        id: 'a8',
        title: 'Cần Thơ – Thành phố miền Tây sông nước',
        summary: 'Chợ nổi Cái Răng và văn hóa sông nước đặc trưng của vùng đồng bằng sông Cửu Long.',
        content: '''Cần Thơ là trung tâm của vùng đồng bằng sông Cửu Long, nơi văn hóa sông nước tồn tại từ hàng trăm năm qua. Chợ nổi Cái Răng là nét văn hóa đặc trưng không thể bỏ qua.''',
        thumbnailUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400',
        source: 'VnExpress Travel',
        publishDate: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ],
  };
}

